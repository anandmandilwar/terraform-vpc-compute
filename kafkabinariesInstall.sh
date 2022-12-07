#!/bin/bash
yum update -y
yum install python3.7 -y
yum install git -y
yum install nmap-ncat -y
yum install jq -y
yum erase awscli -y
amazon-linux-extras install docker -y
yum install java-1.8.0-openjdk-devel -y
service docker start
usermod -a -G docker ec2-user
cd /home/ec2-user
wget https://bootstrap.pypa.io/get-pip.py
su -c "python3.7 get-pip.py --user" -s /bin/sh ec2-user
su -c "/home/ec2-user/.local/bin/pip3 install boto3 --user" -s /bin/sh ec2-user
su -c "/home/ec2-user/.local/bin/pip3 install awscli --user" -s /bin/sh ec2-user
su -c "/home/ec2-user/.local/bin/pip3 install kafka-python --user" -s /bin/sh ec2-user
# install AWS CLI 2 - access with aws2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install -b /usr/local/bin/aws2
su -c "ln -s /usr/local/bin/aws2/aws ~/.local/bin/aws2" -s /bin/sh ec2-user
# Create dirs, get Apache Kafka 2.7.0 and unpack it
su -c "mkdir -p kafka270 confluent" -s /bin/sh ec2-user
cd /home/ec2-user
ln -s /home/ec2-user/kafka270 /home/ec2-user/kafka
cd kafka270
su -c "wget http://archive.apache.org/dist/kafka/2.7.0/kafka_2.12-2.7.0.tgz" -s /bin/sh ec2-user
su -c "tar -xzf kafka_2.12-2.7.0.tgz --strip 1" -s /bin/sh ec2-user

# Get Confluent Community and unpack it
cd /home/ec2-user
cd confluent
su -c "wget http://packages.confluent.io/archive/5.4/confluent-community-5.4.1-2.12.tar.gz" -s /bin/sh ec2-user
su -c "tar -xzf confluent-community-5.4.1-2.12.tar.gz --strip 1" -s /bin/sh ec2-user
            
# Initialize the Kafka cert trust store
su -c 'find /usr/lib/jvm/ -name "cacerts" -exec cp {} /tmp/kafka.client.truststore.jks \;' -s /bin/sh ec2-user

cd /tmp
su -c "mkdir -p kafka" -s /bin/sh ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/producer.properties_msk /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/consumer.properties /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/jars/KafkaClickstreamClient-1.0-SNAPSHOT.jar /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/jars/KafkaClickstreamConsumer-1.0-SNAPSHOT.jar /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/jars/CustomMM2ReplicationPolicy-1.0-SNAPSHOT.jar /home/ec2-user/confluent/share/java/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/jars/MM2GroupOffsetSync-1.0-SNAPSHOT.jar /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/MSKLabs/schema-registry-ssl/schema-registry.properties /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/generatePropertiesFiles.py /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/generateStartupFile.py /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/AuthMSK-1.0-SNAPSHOT.jar /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/connect-distributed.properties /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/kafka-consumer-python.py /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/setup-env.py /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/GlobalSeqNo.py /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/mm2-msc.json /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/mm2-hbc.json /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/mm2-cpc.json /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/mm2-cpc-cust-repl-policy.json /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/mm2-msc-cust-repl-policy.json /tmp/kafka" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/kafka-connect.yml /home/ec2-user/prometheus" -l ec2-user
su -c "aws s3 cp s3://aws-streaming-artifacts/msk-lab-resources/kafka-producer-consumer.yml /home/ec2-user/prometheus" -l ec2-user

# Setup unit in systemd for Schema Registry
echo -n "
[Unit]
Description=Confluent Schema Registry
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/bin/sh -c '/home/ec2-user/confluent/bin/schema-registry-start /tmp/kafka/schema-registry.properties > /tmp/kafka/schema-registry.log 2>&1'
ExecStop=/home/ec2-user/confluent/bin/schema-registry-stop
Restart=on-abnormal

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/confluent-schema-registry.service

# Setup unit in systemd for Kafka Connect
echo -n "
[Unit]
Description=Kafka Connect
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/bin/sh -c '/home/ec2-user/kafka/bin/connect-distributed.sh /tmp/kafka/connect-distributed.properties > /tmp/kafka/kafka-connect.log 2>&1'
Restart=on-abnormal

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/kafka-connect.service

#setup bash env
su -c "echo 'export PS1=\"KafkaClientEC2Instance1 [\u@\h \W\\]$ \"' >> /home/ec2-user/.bash_profile" -s /bin/sh ec2-user
su -c "echo '[ -f /tmp/kafka/setup_env ] && . /tmp/kafka/setup_env' >> /home/ec2-user/.bash_profile" -s /bin/sh ec2-user
