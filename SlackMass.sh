# colors
BLU="\e[94m"
RED="\e[91m"
RST="\e[0m"
GRN="\e[92m"
YEL="\e[93m"

echo "Remember that the script needs to be launched with Sudo rights"

read -p "Please enter the domain Name: " domain
read -p "Please enter your Slack webhook: " webhook
read -p "Please enter the location of your Amass database (f.ex.: /~/.config/amass): " db

# Catch error
if [ -z "$domain" ]; then
    echo "$RED[+] ERROR: You have not entered the Domain Name."
    exit 1
elif [ -z "$webhook" ]; then
    echo "$RED[+] ERROR: You have not entered the webhook"
    exit 1
elif [ -z "$db" ]; then
    echo "$RED[+] ERROR: You have not entered the Amass database"
    exit 1
else
    echo "$BLU[+] Starting subdomain enumeration on $domain"
fi

mkdir $domain
mkdir $domain/aquatone

while true
    do
    subfinder -d $domain -silent | anew ./$domain/subs.txt
    assetfinder -subs-only $domain | anew ./$domain/subs.txt
    amass enum -passive -d $domain | anew ./$domain/subs.txt

    echo "$BLU[+] Starting httpx"
    cat ./$domain/subs.txt | httpx -silent | anew ./$domain/alive.txt

    amass track -dir $db -d $domain -last 3 >/dev/null
    if [ $? -eq 1 ]; then
        echo "$BLU[+] It was your first or second time running Amass on $domain, sending results to Slack"
        cat ./$domain/alive.txt | ./slackcat -u $webhook >/dev/null
    else 
        echo  "$BLU[+] Comparing results with previous two Amass enums"
        # Check if there are changes to not spam Slack
        amass track -dir $db -d $domain -last 3 > ./$domain/track-amass.txt
        if cat ./$domain/track-amass.txt | grep -q "No differences discovered"; then
            echo "$BLU[+] No differences discovered"
            rm -rf ./$domain/track-amass.txt
        else
            cat ./$domain/track-amass.txt | ./slackcat -u $webhook >/dev/null
            rm -rf ./$domain/track-amass.txt
        fi
    fi

    echo "$BLU[+] Starting Aquatone (sudo required)"
    sudo aquatone -input-file ./$domain/alive.txt -out ./$domain/aquatone -screenshot-delay 10000
    sudo chmod 777 -R ./$domain/aquatone

    echo "$BLU[+] Starting nuclei" 
    cat ./$domain/alive.txt | nuclei -t /home/kali/cent-nuclei-templates -es info,unknown -etags ssl,network | anew ./$domain/nuclei.txt | ./slackcat -u $webhook 
    echo  '\n'

    echo  "$BLU[+] Starting a new SlackMass of $domain in 1 minute"
    sleep 1m
done      

echo  "$GRN[+] SlackMass has done its work. Have a good day. Quitting......$RST\n"

fi