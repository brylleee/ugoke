ART_ID="$1"
SESSID="$2"
DELAY="$3"

# Error handling
function crash {
    printf "\033[1;31mFatal Error! $1\n"
    printf "\033[1;33mExiting...\033[1;30m\n"
    exit
}

if [ "$ART_ID" == "" ]; then
    # Output help if supplied with no arguments
    printf "ugoke v0.2\n"
    printf "Download Pixiv (ugoira) from the command line\n\n"
    printf "Usage: ugoke <art id> <session id> <delay>\n"
    printf "ART ID: Number that uniquely identifies the artwork\n"
    printf "        https://www.pixiv.net/en/artworks/<art id>\n\n"
    printf "SESSION ID(optional): PHPSESSID cookie to download restricted artworks such as R18\n"
    printf "DELAY(optional):      Delay count for imagemagick's convert command\n\n"
    printf "Run './ugoke setup' to install necessary packages\n"
    exit
fi

if [ "$ART_ID" == "setup" ]; then
    # Download necessary packages
    printf "\033[1;33mDownloading jq and imagemagick...\n"
    apt install jq > /dev/null & spinner          # For parsing JSON
    apt install imagemagick > /dev/null & spinner # Converting PNGs to GIF
    printf "\033[1;33mDone!\033[0;30m\n"
    exit
fi

# URLs
META_INFO="https://www.pixiv.net/ajax/illust/${ART_ID}/ugoira_meta"
ART_URL="https://www.pixiv.net/member_illust.php?mode=medium&illust_id=${ART_ID}"

# Google Chrome User Agent (Very common)
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"

# Get original source file (zip)
printf "\033[1;33mGetting original source file...\n"
SOURCE=$(curl -s "$META_INFO" -A "$USER_AGENT" --cookie "PHPSESSID=${SESSID}" | jq '.body .originalSrc')
CSOURCE=$(echo "$SOURCE" | sed 's/\\//g' | tr -d '"')
printf "\033[1;33mDownloading original source file...\n"
curl -s "$CSOURCE" -e "$ART_URL" -A "$USER_AGENT" --cookie "PHPSESSID=${SESSID}" -o "${ART_ID}.zip" > /dev/null || crash "Could not download ugoira, check if you have internet connection, if the art id is correct, or if you supplied wrong or no Session ID"

# Apply default delay if not custom
if [ "$DELAY" == "" ]; then
   MS=$(curl -s "$META_INFO" -A "$USER_AGENT" --cookie "PHPSESSID=${SESSID}" | jq '.body .frames[0] .delay')
   DELAY=$(($MS/10))  # imagemagick's convert command accept centiseconds as delay
fi

# Extract and convert
printf "\033[1;33mExtracting contents...\n"
mkdir "$ART_ID" || crash "Can't create directory!"
cd "$ART_ID"
unzip "../${ART_ID}.zip" > /dev/null
printf "\033[1;33mConverting to gif with $DELAY centisecond(s) delay...\n"
convert -delay "$DELAY" -loop 0 *.jpg "${ART_ID}.gif"
rm *.jpg || crash "Bro, I literally cannot clean my mess! Go clean it up yourself"

printf "\033[1;33mDone! Saved as ./${ART_ID}/${ART_ID}.gif\n"

# Restart colors
printf "\033[0;30m"
