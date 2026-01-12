# sudo yum install java -y
sudo yum install git -y
# sudo yum install maven -y
sudo yum install docker -y
sudo service docker start


if [ -d "addressbook" ]
then
  echo "repo is cloned and exists"
  cd /home/ec2-user/addressbook
  git pull origin master
else
  git clone https://github.com/jassu810/addressbook.git
fi

cd /home/ec2-user/addressbook
# mvn package

sudo docker build -t $1 .