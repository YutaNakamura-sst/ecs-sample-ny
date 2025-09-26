#!/bin/bash

# 引数から環境識別子を読み込み
if [ ! -z "$1" ]; then
    CONFIG_FILE_PATH="$(dirname $0)/../envs/${1}.yml"
fi

# 環境識別子に対応する設定ファイルがあるかチェック
if [ ! -e "${CONFIG_FILE_PATH}" ]; then
    echo ""
    echo "Config file does not exist on [${CONFIG_FILE_PATH}]."
    echo ""
fi

# 設定ファイルからパラメータを読み込み
PARAMETERS=$(yq '.Parameters | to_entries().[] | .key + "=\"" + .value + "\""' ${CONFIG_FILE_PATH})
eval ${PARAMETERS}
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
ECR_DOMAIN=${ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com
ECR_REPOSITORY_NAME=${AppId}-${EnvId}-webapp
IMAGE_TAG=$(cat version.txt | head -1)

# CloudFormation用ロールの読み込み
CFN_ROLE_ARN=$(aws cloudformation list-exports --region ap-northeast-1 --query 'Exports[?Name==`'${AppId}-${EnvId}-cfn-iam-role-arn'`].Value' --output text)

# ECS Base スタックのデプロイ
sam deploy \
    --stack-name ${AppId}-${EnvId}-ecs-base-stack \
    --template-file templates/ecs-base.yml \
    --region ap-northeast-1 \
    --role-arn ${CFN_ROLE_ARN} \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides ${PARAMETERS} \
    --resolve-s3 \
    --no-fail-on-empty-changeset
    
# コンテナイメージのECRへのプッシュ
NUM_OF_SAME_IMAGES_ON_ECR=$(aws ecr batch-get-image --repository-name ${ECR_REPOSITORY_NAME} --image-ids imageTag=${IMAGE_TAG} --query "length(images)")
if [ "${NUM_OF_SAME_IMAGES_ON_ECR}" -eq 0 ]; then

    cd ./src/demo

    # Gradleビルドの実行
    chmod +x ./gradlew  # 実行権限を付与
    ./gradlew clean build
    if [ $? -ne 0 ]; then
        echo "Gradle build failed. Exiting."
        exit 1
    fi

    cd ../../

    docker login -u naoyuki_sugiyama@sst-web.com -p Sst900249:
    
    # コンテナイメージのビルド
    aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${ECR_DOMAIN}
    docker build -t ${ECR_DOMAIN}/${ECR_REPOSITORY_NAME}:latest .
    docker images ${ECR_DOMAIN}/${ECR_REPOSITORY_NAME}:latest
    docker tag ${ECR_DOMAIN}/${ECR_REPOSITORY_NAME}:latest ${ECR_DOMAIN}/${ECR_REPOSITORY_NAME}:${IMAGE_TAG}
    docker push ${ECR_DOMAIN}/${ECR_REPOSITORY_NAME}:latest
    docker push ${ECR_DOMAIN}/${ECR_REPOSITORY_NAME}:${IMAGE_TAG}
fi

# ECS WebApp スタックのデプロイ
sam deploy \
    --stack-name ${AppId}-${EnvId}-ecs-webapp-stack \
    --template-file templates/ecs-webapp.yml \
    --region ap-northeast-1 \
    --role-arn ${CFN_ROLE_ARN} \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides ${PARAMETERS} ImageTag=${IMAGE_TAG} \
    --resolve-s3 \
    --no-fail-on-empty-changeset

# ECS night stop base スタックのデプロイ
sam deploy \
    --stack-name ${AppId}-${EnvId}-ecs-night-stop-base-stack \
    --template-file templates/ecs-night-stop-base.yml \
    --region ap-northeast-1 \
    --role-arn ${CFN_ROLE_ARN} \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides ${PARAMETERS} \
    --resolve-s3 \
    --no-fail-on-empty-changeset

# ECS night-stop スタックのデプロイ
sam deploy \
    --stack-name ${AppId}-${EnvId}-ecs-night-stop-stack \
    --template-file templates/ecs-night-stop.yml \
    --region ap-northeast-1 \
    --role-arn ${CFN_ROLE_ARN} \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides ${PARAMETERS} \
    --resolve-s3 \
    --no-fail-on-empty-changeset