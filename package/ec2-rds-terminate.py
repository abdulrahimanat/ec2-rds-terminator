import boto3
from botocore.exceptions import ClientError
def handler(event, context):
    TagValue = 'true'
    TagKey = 'AutoTerminate'
    client = boto3.client('rds')
    response = client.describe_db_instances()
    ec2 = boto3.resource('ec2')
    filters = [{
        'Name': 'tag:AutoTerminate',
        'Values': ['true']
      }
    ]
  
    # Filter instances that should terminate
    instances = ec2.instances.filter(Filters=filters)
  
    # Retrieve instance IDs
    instance_ids = [instance.id for instance in instances]
  
    # Terminateing instances
    terminating_instances = ec2.instances.filter(Filters=[{'Name': 'instance-id', 'Values': instance_ids}]).terminate()
    
    # RDS terminating
    for resp in response['DBInstances']:
       db_instance_arn = resp['DBInstanceArn']
       response = client.list_tags_for_resource(ResourceName = db_instance_arn)
       for tags in response['TagList']:
           if tags['Key'] == str(TagKey) and tags['Value'] == str(TagValue):
               DbName = resp['DBInstanceIdentifier']
               print(DbName)# print(status)
               try:
                   response = client.delete_db_instance(
                      DBInstanceIdentifier=DbName,
                      SkipFinalSnapshot=True
               )
                   print('Successfully Deleted :: ')
               except ClientError as e:
                   print(e)
                   data = {"Failed to Terminate RDS: `{DbName}` \nERROR:  {str(e)}"}
                   print(data)

