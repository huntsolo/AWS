#Declare an arrays with DNS values
ArDNS=( ec2-52-16-233-180.eu-west-1.compute.amazonaws.com ec2-34-244-84-54.eu-west-1.compute.amazonaws.com ec2-52-208-60-130.eu-west-1.compute.amazonaws.com)

#Function return instanceID value by key pair
function InId (){
aws ec2 describe-instances --filters "Name=key-name,Values=AKIAJZ2POCKFGLM2PNTA"| jq -r .Reservations[].Instances[].InstanceId
}
#Function return instance state code value by DNS
function InSt (){
aws ec2 describe-instances --filters "Name= dns-name,Values=$instanceDNS" | jq -r .Reservations[].Instances[].State.Code
}
#Function return instance state code value by ID
function InStId (){
    aws ec2 describe-instances --filters "Name= instance-id,Values=$instanceIDS" | jq -r .Reservations[].Instances[].State.Code
}
#Function return instance state name value
function InStName (){
    aws ec2 describe-instances --filters "Name= instance-id,Values=$instanceIDS" | jq -r .Reservations[].Instances[].State.Name
}
#Function return instance name value
function InName (){
    aws ec2 describe-instances --instance-ids $instanceIDS | jq -r .Reservations[].Instances[].Tags[].Value
}
#Function creates an image
function ImCreate(){
aws ec2 create-image --instance-id $instanceIDS --name "$(InName) $(date +%Y"."%m"."%d" "%H"-"%M"-"%S)" --description "$(InName) $(date +%Y"."%m"."%d" "%H"-"%M"-"%S)" | jq -r .ImageId
}
#Function return image creation date and ID value for all image which names content instance name from wich image created
function ImCreationDate(){
aws ec2 describe-images --filters "Name=name ,Values=$ImgSearchName*" | jq -r .Images[].CreationDate
aws ec2 describe-images --filters "Name=name ,Values=$ImgSearchName*" | jq -r .Images[].ImageId
}

#Get instanceID in array
ArInstanceId=($(InId))

#Date for image age verification
checkDate=$( date "+%Y-%m-%d" --date "-7 day" )

codeStop=80
codeStart=16
count=0
#Image search need attribute
doImageSearch=0

#search instance dy DNS name with state status 16
for instanceDNS in ${ArDNS[@]}
do
    instanceIDS=${ArInstanceId[count]}
    if [[ "$(InSt)" =~ "$codeStart" ]]; then
    #if we find
           echo -e Instance "${ArDNS[count]}" is "\e[32mstarted\e[0m"
    else
    #search instance by ID with state status 80 in the images was createm with my key pair
        for instanceIDS in ${ArInstanceId[@]}
	do
            if [[ "$(InStId)" =~ "$codeStop" ]]; then
            #if we find
                echo -e Instance $(InName) must be "\e[31mterminated\e[0m"
            #that we created image from stopped instance
                imageID=$(ImCreate)
            #Image search need attribute is true
                doImageSearch=1
                #Take one part image name for function of image search
                ImgSearchName=$(InName)
                echo -e Image create with ID "\e[1;33m$imageID\e[0m"
            #and delete instance
                echo -e Instance $instanceIDS was "\e[31mterminated\e[0m"
                #aws ec2 terminate-instances --instance-ids ${ArInstanceId[count]}
            fi
	done
    fi
    count=$(($count + 1))
done

count=0

if [ $doImageSearch -eq 1 ]; then
#enter the image creatione date and imageID values in array
ImTime=($(ImCreationDate))
#get the length of the array this will be our counter
ImTimeLen=${#ImTime[*]}

#search image with creation date more 7 days
for ((i=1; i<=${#ImTime[*]}/2 ; i++))
do
    ImDataCrTime=${ImTime[count]:0:10}
    echo "Image creation date" $ImDataCrTime
    if [ "`date -d "$ImDataCrTime" +%s`" -le "`date -d "$checkDate" +%s`" ]; then
    #if we find we delete image
        echo Image ${ImTime[count+${#ImTime[*]}/2]} must be deleted 
        aws ec2 describe-images --image-ids ${ImTime[count+${#ImTime[*]}/2]}
    else
        echo ${ImTime[count+${#ImTime[*]}/2]} was created less than 7 days ago
    fi
    count=$(($count + 1))
done
fi

count=0

#output instance state condition in color
for instanceIDS in ${ArInstanceId[@]}
do
echo -e Instance "\e[32m${ArDNS[count]}\e[0m" with ID - "\e[32m${ArInstanceId[count]}\e[0m" is "\e[32m$(InStName)\e[0m"
count=$(($count + 1))
done