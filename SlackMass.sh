# colors
BLU="\e[94m"
RED="\e[91m"
RST="\e[0m"
GRN="\e[92m"
YEL="\e[93m"

read -p "Please enter the domain Name: " domain
read -p "Please enter your Slack webhook: " webhook

# Catch error
if [ -z "$domain" ]; then
        echo "$RED[+] ERROR: You have not entered the Domain Name."
        exit 1
elif [ -z "$webhook" ]; then
    echo "$RED[+] ERROR: You have not entered the webhook"
    exit 1
else
    echo "$BLU[+] Starting Amass on$RED $domain"
fi

trap "reset && echo '\n $RED[-] Ctrl+C was Pressed! SlackMass quitting...\n' && exit" INT


while true
    do
    amass enum -passive -d $domain -src > enum.txt
    echo '\n'
    cat enum.txt
    echo '\n'
    amass track -dir /home/kali/.config/amass -d $domain -last 2
    if [ $? -eq 1 ]; then
        echo "$BLU[+] It was your first time running Amass on$RED $domain, sending results to Slack"
        cat enum.txt | ./slackcat -u $webhook >/dev/null
        rm -rf enum.txt
    else 
        echo  "$BLU[+] Comparing results with previous Amass enum"
        # Check if there are changes to not spam Slack
        amass track -dir /home/kali/.config/amass -d $domain -last 2 > $domain.txt
        if cat $domain.txt | grep -q "No differences discovered"; then
            echo "$BLU[+] No differences discovered"
            rm -rf $domain.txt
            rm -rf enum.txt
        else
            cat $domain.txt | ./slackcat -u $webhook >/dev/null
            rm -rf $domain.txt
            rm -rf enum.txt
        fi
    fi
    echo  '\n'
    echo  "$BLU[+] Starting in 30 minutes a new Amass scan of$RED $domain"
    sleep 30m
done      

echo  "$GRN[+] SlackMass has done its work. Have a good day. Quitting......$RST\n"

fi