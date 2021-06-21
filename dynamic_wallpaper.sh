#!/bin/bash
#
# PROGRAM: dynamic_wallpaper.sh
# PURPOSE: Enables Dynamic Wallpapers for Windows Terminal (using WSL)
# AUTHOR:  Chayse McMillan -- McMillan Software Solutions LLC
# DETAILS: 
#
#       1) Make sure your windows terminal background is set to 
#           "${THE_DIR}${CONST_BASE}.${PHOTO_FORMAT}" the default is:
#           /mnt/c/Users/${WINDOWS_USER}/Pictures/Ubuntu/Ubuntu.gif
#           
#           This step is done through the TERMINAL Settings!
#
#           example:
#               "backgroundImage": "C:/Users/my_user/Pictures/Ubuntu/Ubuntu.gif",
#               "backgroundImageOpacity": 0.69999998807907104,
#               "backgroundImageStretchMode": "uniformToFill",
#
#       2) Save this program as "~/.dynamic_wallpaper.sh"
#
#       3) Run "chmod 777 dynamic_wallpaper.sh" to update permissions
#
#       4) Open "~/.bashrc" (or "~/.bash_aliases") and add the following line:
#           "( . ~/.dynamic_terminal.sh >/dev/null 2>&1 & ) >/dev/null 2>&1"
#
#       5) Configure the desired variables below
#           WINDOWS_USER is the only non-initialized variable
#
#       6) Create a folder INSIDE your windows pictures folder that mirrors
#           your "CONST_BASE" variable. Full path is held in "THE_DIR".
#
#       7) Add your photos to the folder you created in step 6!
#
#
#------------------------------------------------------------------------
#                   PLEASE INITIALIZE THE FOLLOWING VARIABLES
#
WINDOWS_USER="your_username"                                                        # Your Windows Username
CONST_BASE="Ubuntu"                                                                 # The Directory name to hold the photos         
THE_DIR="/mnt/c/Users/${WINDOWS_USER}/Pictures/${CONST_BASE}/"                      # Full path for the image files   
#------------------------------------------------------------------------
#
#
#
#
#
#
#
#
# Globals
PHOTO_FORMAT="gif"                                                                  # Leave this to enable gif images
VALIDATE_IMGS="1"                                                                   # Formats the image names if needed
VALIDATE_IMG_ORDER="1"                                                              # Makes sure everything is in order
AUTO_IMG_SHIFT="1"                                                                  # Enables the dynamic wallpapers
VALID_FORMATS=("jpg png gif")                                                       # Supported image formats
NUM_FILES=$(ls ${THE_DIR} 2> /dev/null | wc -l)                                     # Number of file in Photo Dir
WHOAMI=$(whoami)                                                                    # The linux user
RUNTIME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"     # Runtime Dir



#
# Main Function
#
main()
{
    # Convert the photos as needed
    if [ "$VALIDATE_IMGS" == "1" ]; then
        validateImageFiles
    fi

    # Check the image order
    if [ "$NUM_FILES" -gt "1" ] && [ "$VALIDATE_IMG_ORDER" == "1" ]; then
        checkImageOrder
    fi

    # Shift the images
    if [ "$AUTO_IMG_SHIFT" == "1" ]; then
        shiftImages
    fi
}




#
# Convert the image names to the appropriate format if needed
#
validateImageFiles()
(
    # Check the photo dir
    checkInitPhotoDir

    # Are there any images in our path?
    if [ "$NUM_FILES" -eq "0"  ]; then
        errorHeader
        printf "\t\tOne image required in: ${THE_DIR}\n\n"
        exit 1 >/dev/null 2>&1
    fi

    # Check the formatting based on our settings
    for FILENAME in "$THE_DIR"* ; do

        # Parse the filename information -- control vars
        local FILE=$(basename -- "$FILENAME")
        local FILE_EXT="${FILE##*.}"
        local FILE_BASE="${FILE%.*}"

        # Quick Numeric Check on File Number
        BAD_NUMERIC=0
        if [ "${#FILE_BASE}" -gt "6" ] && [ "${FILE_BASE:0:6}" == "${CONST_BASE}" ]; then
            NUMERIC_CHECK=${FILE_BASE:6}
            re='^[0-9]+$'
            if [[ ! $NUMERIC_CHECK =~ $re ]]; then
                BAD_NUMERIC=1
            fi
        fi

        # Check for a valid name, extension and possible numerics
        if [ "${FILE_BASE:0:6}" != "$CONST_BASE" ] || [ "$BAD_NUMERIC" -eq "1" ] || [ "$FILE_EXT" != "$PHOTO_FORMAT" ] ; then

            # Remove bad files (file extension check)
            if [[ ! " ${VALID_FORMATS[@]} " =~ " ${FILE_EXT} " ]]; then
                rm "$FILENAME"

            elif [ "${FILE_BASE}.${FILE_EXT}" != "${CONST_BASE}.${PHOTO_FORMAT}" ]; then
                # Get the first avaliable file name
                getAvaliableFile
                
                # Move the file
                mv $FILENAME $NEW_F
            fi
        fi
    done
)




#
# Init the Photo Dir (If Needed)
#
checkInitPhotoDir()
{
    # Did the user populate the desired variable WINDOWS_USER?
    if [ -z "$WINDOWS_USER" ]; then
        errorHeader
        printf "\t\tPlease populate the \"WINDOWS_USER\" variable in:\n\t\t${RUNTIME_DIR}/dynamic_wallpaper.sh\n\n"
        exit 1 >/dev/null 2>&1
    fi

    # Create our image dir?
    if [ ! -d $THE_DIR ]; then
        mkdir $THE_DIR
    fi
}





#
# Shift the background images
#
shiftImages()
{
    # Loop the files
    START=1
    i=$START
    MOVE_NUM=1
    while [[ $i -le $NUM_FILES ]]
    do
        # The file number
        ((MOVE_NUM = i - 1))
    ​
        # Check for first iteration
        if [ $MOVE_NUM == 0 ]; then
            mv "${THE_DIR}${CONST_BASE}.gif" "${THE_DIR}${CONST_BASE}_TMP.gif"
            
        # Check for last iteration
        elif [ $i == $NUM_FILES ]; then
            mv "${THE_DIR}${CONST_BASE}${MOVE_NUM}_TMP.gif" "${THE_DIR}${CONST_BASE}.gif"
            mv "${THE_DIR}${CONST_BASE}_TMP.gif" "${THE_DIR}${CONST_BASE}${START}.gif"
    ​
        # General Move
        else
            # Stage the first temp move
            if [ $MOVE_NUM == 1 ]; then
                mv "${THE_DIR}${CONST_BASE}${MOVE_NUM}.gif" "${THE_DIR}${CONST_BASE}${MOVE_NUM}_TMP.gif"
            fi
    ​
            # Move the next file to temp so we dont blow it away
            mv "${THE_DIR}${CONST_BASE}${i}.gif" "${THE_DIR}${CONST_BASE}${i}_TMP.gif"
    ​
            # Move the current file
            mv "${THE_DIR}${CONST_BASE}${MOVE_NUM}_TMP.gif" "${THE_DIR}${CONST_BASE}${i}.gif"
        fi
    ​
        # Increment counter
        ((i = i + 1))
    done
}






#
# Verifies the images are in order for the "for loop" - ran after numeric checks
#
checkImageOrder()
{
    # Loop em'
    MOVED_IT=0
    getAvaliableFile
    COMP_BASE=${NEW_F_BASE:6}
    PROCESS_CT=0

    for FILENAME in "$THE_DIR"* ; do
        
        # Control vars
        local FILE=$(basename -- "$FILENAME")
        local FILE_EXT="${FILE##*.}"
        local FILE_BASE="${FILE%.*}"

        # Get the avaliable file information
        if [ "$MOVED_IT" == "1" ]; then
            getAvaliableFile
            COMP_BASE=${NEW_F_BASE:6}
            MOVED_IT=0
        fi
        
        # Should we check it?
        if [ "${#FILE_BASE}" -gt "6" ] && [ "${FILE_BASE:0:6}" == "$CONST_BASE" ]; then

            # Quick Numeric Check
            NUMERIC_CHECK=${FILE_BASE:6}
            re='^[0-9]+$'
            if [[ $NUMERIC_CHECK =~ $re ]]; then

                # Base file doesnt exist, but base + numeric does -- triggered on first iteration only
                if [ "$NUM_FILES" -gt "1" ] && [ ! -f "${THE_DIR}${CONST_BASE}.${PHOTO_FORMAT}" ] && [ "$MOVED_IT" == "0" ]; then
                    mv "$FILENAME" "${THE_DIR}${CONST_BASE}.${PHOTO_FORMAT}"                    # Move it!
                    MOVED_IT=1
                fi

                # If the avaliable file number is ever less than the current file, move it!
                if [ "$NUMERIC_CHECK" -gt "$COMP_BASE" ]; then
                    mv "$FILENAME" "${THE_DIR}${CONST_BASE}${COMP_BASE}.${PHOTO_FORMAT}"     # Move it!
                    MOVED_IT=1
                fi
            else
                errorHeader
                printf "\t\tBad Numeric File Identifier Detected in:\n\t\t${RUNTIME_DIR}/dynamic_wallpaper.sh\n\t\tFile:${FILENAME}\n\t\tPlease call validateImageFiles() before checkImageOrder()\n\n"
                exit 1 >/dev/null 2>&1 
            fi
        else
            if [ "$FILE" != "${CONST_BASE}.${PHOTO_FORMAT}" ]; then
                errorHeader
                printf "\t\tBad File Name Detected in:\n\t\t${RUNTIME_DIR}/dynamic_wallpaper.sh\n\t\tFile:${FILENAME}\n\t\tPlease call validateImageFiles() before checkImageOrder()\n\n"
                exit 1 >/dev/null 2>&1 
            fi
        fi

        # Break to save processing (we're moving files)
        if [ "$PROCESS_CT" -gt "$NUM_FILES" ]; then
            break
        else
            PROCESS_CT=$((PROCESS_CT + 1))
        fi
    done
}





#
# Sets a var for the first avaliable file name
#
getAvaliableFile()
{
    MOVE_CT=0
    GOT_FILE=0
    CHECK_F=$CONST_BASE
    while [ "$GOT_FILE" -eq "0" ] ; do

        # Can we move the file here?
        if [ ! -f "${THE_DIR}${CHECK_F}.${PHOTO_FORMAT}" ]; then

            #  Set the new fname
            GOT_FILE=1
            NEW_F="${THE_DIR}${CHECK_F}.${PHOTO_FORMAT}"     
            break
        fi

        # Increment counter
        MOVE_CT=$((MOVE_CT + 1))

        # Update Vars
        CHECK_F="${CONST_BASE}${MOVE_CT}"
    done

    # Just for Reference!
    TMP_FILE=$(basename -- "$NEW_F")
    NEW_F_EXT="${TMP_FILE##*.}"
    NEW_F_BASE="${TMP_FILE%.*}"
}




#
# Error Header Information
#
errorHeader()
{   printf "\n----------------------------------------------------------------------\n"
    printf "\t\t\t\tERROR!\n----------------------------------------------------------------------\n"
    printf "SCRIPT: \n\t\t${RUNTIME_DIR}/dynamic_wallpaper.sh\n"
    printf "MESSAGE: \n"
}



# Do it!
main
return
