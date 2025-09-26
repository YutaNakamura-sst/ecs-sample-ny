@echo off
SETLOCAL

REM -------------------------------------------------------------
REM  リリース環境選択
REM -------------------------------------------------------------
SET /P userInput=リリースする環境を選択してください(1:開発, 2:本番) :
IF "%userInput%" == "1" (
    SET profile=aws-dev-cm
    SET EnvId=dev
) ELSE IF "%userInput%" == "2" (
    SET profile=aws-dev-cm
    SET EnvId=prd
) ELSE (
    echo リリース環境が不正です。中断します。
    exit /B 1
)
REM -------------------------------------------------------------

REM -------------------------------------------------------------
REM  パラメータ定義
REM -------------------------------------------------------------
FOR /F "tokens=*" %%i IN ('aws configure get region --profile %profile%') DO SET AWS_REGION=%%i

IF "%AWS_REGION%" == "ap-northeast-1" (
    SET Region=ap-northeast-1
) ELSE (
    echo リージョンが不正です。中断します。
    exit /B 1
)

FOR /F "tokens=*" %%i IN ('aws sts get-caller-identity --query Account --output text --profile %profile%') DO SET AWS_ACCOUNT_ID=%%i

SET AppId=ecs-sample-ny
SET TargetBranchName=main
SET CodeStarConnectionName=ae361550-6b6e-4075-a064-5e69fc598d35
SET FullRepositoryId=YutaNakamura-sst/ecs-sample-ny
SET PARAMETERS=AppId=%AppId% EnvId=%EnvId% TargetBranchName=%TargetBranchName% CodeStarConnectionName=%CodeStarConnectionName% FullRepositoryId=%FullRepositoryId%
echo PARAMETERS=%PARAMETERS%
echo AWS_ACCOUNT_ID=%AWS_ACCOUNT_ID%

REM -------------------------------------------------------------
REM  リリース開始確認
REM -------------------------------------------------------------
SET /P userInput=リリース開始します。よろしいですか？(y/n) :
IF NOT "%userInput%" == "y" (
    echo リリースを中断します。
    exit /B 1
)
REM -------------------------------------------------------------

SET STACK_NAME=cf-%AppId%-%EnvId%-cfn-role
echo %STACK_NAME%

REM sam deploy の実行
sam deploy ^
    --stack-name %STACK_NAME% ^
    --region $Region ^
    --capabilities CAPABILITY_NAMED_IAM ^
    --template-file "../templates/cfn-role.yml" ^
    --parameter-overrides %PARAMETERS% ^
    --resolve-s3 ^
    --no-fail-on-empty-changeset ^
    --profile %profile%

SET STACK_NAME=cf-%AppId%-%EnvId%-cicd-pipeline
echo %STACK_NAME%

sam deploy ^
    --stack-name %STACK_NAME% ^
    --region $Region ^
    --capabilities CAPABILITY_NAMED_IAM ^
    --template-file "../templates/cicd-pipeline-github.yml" ^
    --parameter-overrides %PARAMETERS% ^
    --resolve-s3 ^
    --no-fail-on-empty-changeset ^
    --profile %profile%
