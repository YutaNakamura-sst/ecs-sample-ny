import boto3
import os

def lambda_handler(event, context):
    # ECSクラスタ名
    cluster_name = event['ECS_CLUSTER_NAME']
    # ECSサービス名
    service_name = event['ECS_SERVICE_NAME']

    # ECSクライアントオブジェクトを作成
    ecs_client = boto3.client('ecs')

    # ECSサービスの状態を取得
    response = ecs_client.describe_services(
        cluster=cluster_name,
        services=[service_name]
    )

    # ECSサービスがRUNNING状態であるか確認
    if response['services'][0]['status'] == 'ACTIVE':
        # ECSサービスを停止
        ecs_client.update_service(
            cluster=cluster_name,
            service=service_name,
            desiredCount=0
        )
        print('Stopped ECS service: {}'.format(service_name))
        return {
            'statusCode': 200,
            'body': 'Stopped ECS service successfully'
        }
    else:
        print('ECS service is not running')
        return {
            'statusCode': 200,
            'body': 'ECS service is not running'
        }
