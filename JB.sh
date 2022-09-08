#!/bin/bash

###############################################################################
#MENU FUNCTIONS
###############################################################################

#Found at https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu 
#Credit to UNIX Stack Exchange user Alexander Klimetschek

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
function select_option {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

function select_opt {
    select_option "$@" 1>&2
    local result=$?
    echo $result
    return $result
}
###############################################################################
#First Time Set Up
###############################################################################

if ! [ -d "JupyterDirectory" ]; then

	#Setting up JupyterLabs storage and working directory

	echo "Performing first time setup"
	echo ""
	echo "A new folder named JupyterDirectory will be created in your /pi directory"
	echo ""
	echo "Within it will be a folder containing the config file for this program, as well as a folder for storing Jupyter Notebooks and a folder for storing Jupyter Books"
	echo ""
	read -p "To continue press ENTER " tempEnter1
        mkdir "JupyterDirectory"
        mkdir "JupyterDirectory/BashConfig"
	mkdir "JupyterDirectory/Jupyter"
	mkdir "JupyterDirectory/Jupyter/JupyterNotebooks"
	mkdir "JupyterDirectory/Jupyter/JupyterBooks"
	mkdir "JupyterDirectory/EswatiniRepository"
	mkdir "JupyterDirectory/Jupyter/JupyterBooks/ZippedJupyterBooks"
        echo > JupyterDirectory/BashConfig/bashConfig.txt
	echo > JupyterDirectory/BashConfig/PersonalAccessToken.txt
        echo "directoryPath='JupyterDirectory/Jupyter'" > JupyterDirectory/BashConfig/bashConfig.txt
	sleep 3
	echo ""
        echo "Folders Created!"
	echo ""
        echo "It is recomended that you move and store any existing Jupyter Notebooks or Books to the JupyterDirectory folder"
	echo ""

	#Checking to see if the Raspberry Pi is connected to the Internet

	if : >/dev/tcp/8.8.8.8/53; then
		echo "Online"
		echo ""
	else
		echo "Offline"
		echo ""
	fi

	#NEED CODE FOR INSTALLING MOREUTIL/SPONGE

	echo "Installing moreutils"
	echo ""
	sudo apt-get install moreutils
	echo ""
	echo "Moreutils installed"
	echo ""

	#Installing JQ for json files

	if ! [ -x "$(command -v jq --help)" ]; then
		echo "JQ is not installed"
		read -p "JQ is required for this program to run, press ENTER to install" tempEnter2
		echo ""
		sudo apt-get install jq
		echo "JQ has been installed"
		echo ""
	else
		echo "JQ is already installed"
		echo ""
	fi

	#Installing githubs CLI

	echo "Checking to see if the Github CLI is installed..."
	if ! [ -x "$(command -v gh)" ]; then
                echo "Githubs CLI is not installed"
                read -p "Githubs CLI is required for this program to run, press ENTER to install " tempEnter3
		echo ""
		GITHUB_CLI_VERSION=$(curl -s "https://api.github.com/repos/cli/cli/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
	        cd ~
	        curl -Lo gh.deb "https://github.com/cli/cli/releases/latest/download/gh_${GITHUB_CLI_VERSION}_linux_armv6.deb"
	        sudo dpkg -i gh.deb
	        rm -rf gh.deb
		cd
        else
                echo "Githubs CLI is already installed"
        fi
        echo ""

	#Adding username and PAT into config file

	echo "In order to clone the Eswatini repository, you will need a Github Account along with your username and Personal Access Token (PAT)"
	echo "You can generate a PAT by going to:"
	echo "Github Account Settings (Click on your profile icon in top right corner of github and select settings at the bottom of the menu that pops up)"
	echo "Developer Settings (Found at the bottom of the list of options on the left hand side of the page)"
	echo "Personal Access Tokens (Found at the bottom of the list of options on the left hand side of the page)"
	echo "Generate New Token (Found center-right near the top of the page)"
	echo "Give your PAT a descriptive name, set the expiration date to be 'No Expiration' and check off 'REPO', 'WRITE:PACKAGES', and 'USER'"
	echo "Select Generate Token at the bottom of your page and copy the token into your clip board"
	echo ""
	read -p "Enter your Github username: " username
	echo "userName='$username'" >> JupyterDirectory/BashConfig/bashConfig.txt
	read -p "Enter your email associated with your Github account: " email
	echo "userEmail='$email'" >> JupyterDirectory/BashConfig/bashConfig.txt
	read -p "Enter your Personal Access Token: " personalAccessToken
	echo "PAT='$personalAccessToken'" >> JupyterDirectory/BashConfig/bashConfig.txt
	echo "$personalAccessToken" > JupyterDirectory/BashConfig/PersonalAccessToken.txt
	echo ""

	source JupyterDirectory/BashConfig/bashConfig.txt

	#Cloning Eswatini Repository

	echo "Cloning Eswatini Repository"
	git clone https://$userName:$PAT@github.com/University-of-Eswatini/Eswatini-Project.git JupyterDirectory/EswatiniRepository
	echo ""

        #Authenticating GH CLI

        echo "When logging into Github please select:"
        echo ""
        echo "-GitHub.com"
        echo "-HTTPS"
        echo "-Paste an authentication token"
        echo ""
        echo "Here is your authentication token to copy-paste"
        echo ""
        echo "$PAT"
        echo ""
        gh auth login

	#Checking to see if Jupyter Labs is installed

	echo "Checking to see if Jupyter Labs is installed..."
	if ! [ -x "$(command -v jupyter lab)" ]; then
		echo "Jupyter Labs not installed"
		read -p "Jupyter Labs is required for this program to run, press ENTER to install " tempEnter4
		echo ""
                pip install -U jupyter lab
		echo "Jupyter Labs installed!"
	else
		echo "Jupter Labs is already installed"
	fi
	echo ""

	#Checking to see if Jupyter Books is installed

	echo "Checking to see if Jupyter Books is installed..."
        if ! [ -x "$(command -v jupyter-book)" ]; then
                echo "Jupyter Books not installed"
                read -p "Jupyter Books is required for this program to run, press ENTER to install " tempEnter5
		echo ""
                pip install -U jupyter-book
		echo "Jupyter Books installed!"
        else
                echo "Jupter Books is already installed"
        fi
	echo ""
	echo "First time set up complete!"

#If first time set up done then making sure user is logged into GH CLI and updates repository

else

	source JupyterDirectory/BashConfig/bashConfig.txt

	#Checking to make sure user is still logged into GH CLI

	loginStatus=$(gh auth status 2>&1)

	if [[ $loginStatus == *$userName* ]]; then
		echo "Logged into GitHub.com"
		echo ""
	else
		echo "When logging into Github please select:"
	        echo ""
	        echo "-GitHub.com"
	        echo "-HTTPS"
	        echo "-Paste an authentication token"
	        echo ""
	        echo "Here is your authentication token to copy-paste"
	        echo ""
	        echo "$PAT"
	        echo ""
	        gh auth login
	fi

	#Upgrading GitHub CLI

	echo "Checking to see if GitHubs CLI is up to date"
	echo ""
	sudo apt update
	sudo apt install gh
	echo ""

	#Updating local Eswatini repository

	cd JupyterDirectory/EswatiniRepository
	git config pull.rebase false 
	git pull https://github.com/University-of-Eswatini/Eswatini-Project.git main
	cd

fi

declare -i loopConditional=1

echo ""
echo "Welcome to the Jupyter Book and Notebook editor and uploader for the University of Eswatini!"
echo ""

###############################################################################
#Main Menu
###############################################################################

while [ $loopConditional = 1 ]; do

echo "#################################"
echo "            Main Menu"
echo "#################################"
echo ""
echo "Please select from the following:"

case `select_opt "1)Open Jupyter Lab where you can create or edit Jupyter Notebooks" "2)Create a new Jupyter Book" "3)Upload a Jupyter Notebook or Book to the Eswatini textbook resource website" "4)Options Menu" "5)Exit"` in
    0) initialChoice=1;;
    1) initialChoice=2;;
    2) initialChoice=3;;
    3) initialChoice=4;;
    4) initialChoice=5;;
esac

###############################################################################
#1)Open Jupyter Labs where you can create or edit Jupyter Notebooks
###############################################################################

if [ $initialChoice = 1 ]; then
	cd
	echo "Opening Jupyter Lab"
	lxterminal -e jupyter lab --notebook-dir=~/JupyterDirectory/Jupyter
	echo ""

	case `select_opt "1)Return to menu" "2)Exit"` in
	    0) loopConditional=1;;
	    1) loopConditional=2;;
	esac
        initialChoice=100
fi

###############################################################################
#2)Create a new Jupyter Book
###############################################################################

if [ $initialChoice = 2 ]; then
	read -p "Please enter the name of your new Jupyter Book: " jupyterBookName
	while [ -d "JupyterDirectory/JupyterBooks/$jupyterBookName" ]; do
		echo "A book by that name already exists"
		echo "Either delete the book before continuing with your choosen name or choose a different name"
		echo ""
		read -p "Please enter the name of your new Jupyter Book : " jupyterBookName
	done
	if [ -d "JupyterDirectory" ]; then
		jupyter-book create JupyterDirectory/Jupyter/JupyterBooks/$jupyterBookName
	else
		jupyter-book create $jupyterBookName
	fi

	echo ""

        case `select_opt "1)Return to menu" "2)Exit"` in
            0) loopConditional=1;;
            1) loopConditional=2;;
        esac
        initialChoice=100
fi

###############################################################################
#3)Upload a Jupyter Notebook or Book to the Eswatini textbook resource website
###############################################################################

if [ $initialChoice = 3 ]; then

	source JupyterDirectory/BashConfig/bashConfig.txt
	bookOrNotebook=1000

	echo "Would you like to upload a Notebook or Book?"
        case `select_opt "1)Jupyter Notebook" "2)Jupyter Book"` in
            0) bookOrNotebook=1;;
            1) bookOrNotebook=2;;
        esac

	#Jupyter Notebook

	if [ $bookOrNotebook = 1 ]; then
		cd JupyterDirectory/Jupyter/JupyterNotebooks
		notebookArray=($(ls))
		notebookToBeUploaded=""

		echo "Please select the Notebook you wish uploaded from the list below"
		case `select_opt "${notebookArray[@]}"` in
            	    *) notebookToBeUploaded="${notebookArray[$?]}";;
	        esac

		cd
		cd JupyterDirectory/EswatiniRepository/static/books/juypterNotebooks
		overwriteNotebook=3
		exitNotebook=0

		#Checking to see if a Notebook by the same name exits

		if [ -f $notebookToBeUploaded ]; then
                        echo "A notebook by that name already exists"
                        echo "Do you wish to replace it?"
                        case `select_opt "1)Yes" "2)No"` in
                            0) overwriteNotebook=1;;
                            1) overwriteNotebook=2;;
                        esac
			if [ $overwriteNotebook = 1 ]; then
				echo "Deleting $notebookToBeUploaded from the Eswatini Repository"
				rm -f $notebookToBeDeleted
				echo ""
				cd
				cp -r JupyterDirectory/Jupyter/JupyterNotebooks/$notebookToBeUploaded JupyterDirectory/EswatiniRepository/static/books/juypterNotebooks
				exitNotebook=1
			fi
			if [ $overwriteNotebook = 2 ]; then
				echo "It is recommended that you rename the Notebook you wish to upload then"
				exitNotebook=2
			fi
		else
			cd
			cp -r JupyterDirectory/Jupyter/JupyterNotebooks/$notebookToBeUploaded JupyterDirectory/EswatiniRepository/static/books/juypterNotebooks
			exitNotebook=1
		fi

		cd

		if [ $exitNotebook = 1 ]; then

			front='"'
			back='"'

			#FILE

			notebookFile="books/juypterNotebooks/$notebookToBeUploaded"

			#ZIP

			notebookZip=""

			#TYPE

			notebookType="notebook"

			#NAME

			read -p "Enter the title of your Notebook: " notebookName
			echo ""

			#DESCRIPT

			echo "Please enter the description for your Notebook"
			echo "Note that it may be easier to write it else where and copy paste it here"
			echo "If there are more then one paragraphs, please replace the space with '\n\n'"
			echo "Just press enter if there is no description for your notebook"
			read -p "Description: " notebookDescript
			echo ""

			#AUTHOR

			read -p "Enter the author of the Notebook: " notebookAuthor
			echo ""

			#CLASS

	                read -p "Enter the class this Notebook is for: " notebookClass
			echo""

			#IMAGE

			notebookImage=""

			#SUBJECT

			cd JupyterDirectory/EswatiniRepository

			notebookArr=()

			while IFS='' read -r line; do #reads the json file and puts all the keys into an array
	        		notebookArr+=("$line")
			done< <(jq 'keys[]' textbooks.json)

			cd
			notebookSubject=""
			echo "Please select the subject for your Notebook from the list below"
			echo ""

			case `select_opt "${notebookArr[@]}"` in
			    *) notebookSubject="${notebookArr[$?]}";;
			esac

			notebookSubject="${notebookSubject//[\"]}"

			#ADDING THE INFORMATION TO THE JSON FILE

			export NF=$notebookFile
			export NZ=$notebookZip
			export NT=$notebookType
			export NN=$notebookName
			export ND=$notebookDescript
			export NA=$notebookAuthor
			export NC=$notebookClass
			export NI=$notebookImage
			export NS=$notebookSubject

			cd JupyterDirectory/EswatiniRepository
			jq '.[env.NS] += [{"file": env.NF, "zip": env.NZ, "type": env.NT, "name": env.NN, "descript": env.ND, "author": env.NA, "class": env.NC, "image": env.NI}]' textbooks.json | sponge textbooks.json
			cd

	                #CREATING THE PULL REQUEST

			source JupyterDirectory/BashConfig/bashConfig.txt

			cd JupyterDirectory/EswatiniRepository
			read -p "Enter a name for your pull requests branch: " branchName
			branchName="${branchName// /-}"
			git branch $branchName
			git checkout $branchName
			git add .
			git commit -m"Pull request for new Notebook for '$userName'"
			git fetch
			gh pr create
			git checkout main
			git branch -D $branchName
			cd
		else
			cd
		fi
	fi

	#Jupyter Book

	if [ $bookOrNotebook = 2 ]; then

		cd JupyterDirectory/Jupyter/JupyterBooks
		bookArray=($(ls --hide=ZippedJupyterBooks))
		bookToBeUploaded=""

		echo "Please select the Jupyter Book you wish uploaded from the list below"
		echo ""
                case `select_opt "${bookArray[@]}"` in
                    *) bookToBeUploaded="${bookArray[$?]}";;
                esac

		#Building the Jupyter Books HTML

		echo "Building the HTML for your Jupyter Book"
		echo ""
		jupyter-book build $bookToBeUploaded
		echo ""

		#Zipping the Jupyter Book and placing them in correct folders

		echo "Zipping your Jupyter Book..."
		echo ""
		overwriteZip=3
		exitZip=0

		if [ -f "ZippedJupyterBooks/$bookToBeUploaded.zip" ]; then
			echo "This book has already been zipped"
			echo "Do you wish to overwrite it?"
		        case `select_opt "1)Yes" "2)No"` in
		            0) overwriteZip=1;;
		            1) overwriteZip=2;;
		        esac

			if [ $overwriteZip = 1 ]; then
				echo ""
				zip -r - $bookToBeUploaded > ZippedJupyterBooks/$bookToBeUploaded.zip
				cd
				echo ""
				echo "File overwritten"
                		echo ""
                		echo "Your Jupyter Book has been zipped"
                		echo ""
			fi
			if [ $overwriteZip = 2 ]; then
				echo "It is recomended then that you rename the book you wish to upload"
				exitZip=1
			fi
		else
			echo ""
			zip -r ZippedJupyterBooks/$bookToBeUploaded $bookToBeUploaded
                	echo ""
                	echo "Your Jupyter Book has been zipped"
                	echo ""
			cd
		fi
#############################
                cd JupyterDirectory/EswatiniRepository/static/books/juypterBooks
                overwriteBook=3
                exitBook=0

                #Checking to see if a Book by the same name exits

		if [ $exitZip = 0 ]; then

	                if [ -d $bookToBeUploaded ]; then
	                        echo "A Jupyter Book by that name already exists"
	                        echo "Do you wish to replace it?"
	                        case `select_opt "1)Yes" "2)No"` in
	                            0) overwriteBook=1;;
	                            1) overwriteBook=2;;
	                        esac
	                        if [ $overwriteBook = 1 ]; then
	                                echo "Deleting $bookToBeUploaded from the Eswatini Repository"
	                                rm -f $bookToBeDeleted
	                                echo ""
					cd JupyterDirectory/EswatiniRepository/static/books/zippedJuypterBooks
					rm -f $bookToBeDeleted.zip
	                                cd
	                                cp -r JupyterDirectory/Jupyter/JupyterBooks/$bookToBeUploaded JupyterDirectory/EswatiniRepository/static/books/juypterBooks
                			cp -r JupyterDirectory/Jupyter/JupyterBooks/ZippedJupyterBooks/$bookToBeUploaded.zip JupyterDirectory/EswatiniRepository/static/books/zippedJuypterBooks
	                                exitBook=1
	                        fi
	                        if [ $overwriteBook = 2 ]; then
	                                echo "It is recommended that you rename the Jupyter Book you wish to upload then"
	                                exitBook=2
	                        fi
	                else
	                        cd
	                        exitBook=1
	                fi

		cp -r JupyterDirectory/Jupyter/JupyterBooks/$bookToBeUploaded JupyterDirectory/EswatiniRepository/static/books/juypterBooks
		cp -r JupyterDirectory/Jupyter/JupyterBooks/ZippedJupyterBooks/$bookToBeUploaded.zip JupyterDirectory/EswatiniRepository/static/books/zippedJuypterBooks
################################

			if [ $exitbook = 1 ]; then

		                front='"'
		                back='"'

		                #FILE

		                bookFile="books/juypterBooks/$bookToBeUploaded/_build/html/index.html"

		                #ZIP

		                bookZip="books/zippedJuypterBooks/$bookToBeUploaded.zip"

		                #TYPE

		                bookType="book"

		                #NAME

		                read -p "Enter the title of your Jupyter Book: " bookName
		                echo ""

		                #DESCRIPT

		                bookDescript=""

		                #AUTHOR

		                read -p "Enter the author of the Juypter Book: " bookAuthor
		                echo ""

		                #CLASS

		                read -p "Enter the class this Juypter Book is for: " bookClass

		                #IMAGE

		                bookImage=""

		                #SUBJECT

		                cd JupyterDirectory/EswatiniRepository

		                bookArr=()

		                while IFS='' read -r line; do #reads the json file and puts all the keys into an array
		                        bookArr+=("$line")
		                done< <(jq 'keys[]' textbooks.json)

		                cd
		                bookSubject=""
		                echo "Please select the subject for your Jupyter Book from the list below"
		                echo ""

		                case `select_opt "${bookArr[@]}"` in
		                    *) bookSubject="${bookArr[$?]}";;
		                esac

		                bookSubject="${bookSubject//[\"]}"

		                #ADDING THE INFORMATION TO THE JSON FILE

		                export BF=$bookFile
		                export BZ=$bookZip
		                export BT=$bookType
		                export BN=$bookName
		                export BD=$bookDescript
		                export BA=$bookAuthor
		                export BC=$bookClass
		                export BI=$bookImage
		                export BS=$bookSubject

		                cd JupyterDirectory/EswatiniRepository
		                jq '.[env.BS] += [{"file": env.BF, "zip": env.BZ, "type": env.BT, "name": env.BN, "descript": env.BD, "author": env.BA, "class": env.BC, "image": env.BI}]' textbooks.json | sponge textbooks.json
		                cd

				#CREATING THE PULL REQUEST

		                source JupyterDirectory/BashConfig/bashConfig.txt

		                cd JupyterDirectory/EswatiniRepository
		                read -p "Enter a name for your pull requests branch: " branchName
		                branchName="${branchName// /-}"
		                git branch $branchName
		                git checkout $branchName
		                git add .
		                git commit -m"Pull request for new Juypter Book for '$userName'"
				git fetch
		                gh pr create
				git checkout main
				git branch -D $branchName
		                cd
			else
				cd
			fi
		else
			cd
		fi
	fi
	echo ""
        case `select_opt "1)Return to menu" "2)Exit"` in
            0) loopConditional=1;;
            1) loopConditional=2;;
        esac
        initialChoice=100

fi

###############################################################################
#4)Options Menu
###############################################################################

if [ $initialChoice = 4 ]; then

	optionsMenu=1

	while [ $optionsMenu = 1 ]; do

		echo "#################################"
		echo "          Options Menu"
		echo "#################################"
		echo ""
		echo "Please select from the following:"

		optionsChoice=0

		case `select_opt "1)Update your Eswatini Repository (Git Pull)" "2)Update your GitHub credentials" "3)Back to Main Menu"` in
		    0) optionsChoice=1;;
		    1) optionsChoice=2;;
		    2) optionsChoice=3;;
		esac

		#Update Eswatini Repository
		if [ $optionsChoice = 1 ]; then
			echo "Updating Eswatini Respository..."
			echo ""
	       	 	cd JupyterDirectory/EswatiniRepository
	        	git config pull.rebase false
	        	git pull https://github.com/University-of-Eswatini/Eswatini-Project.git main
	        	cd
			echo ""
			optionsChoice=0
		fi

		#Update Github Credentials
		if [ $optionsChoice = 2 ]; then
			> JupyterDirectory/BashConfig/bashConfig.txt
			> JupyterDirectory/BashConfig/PersonalAccessToken.txt
			echo ""
		        echo "directoryPath='JupyterDirectory/Jupyter'" > JupyterDirectory/BashConfig/bashConfig.txt
	        	read -p "Enter your Github username: " username
	       		echo "userName='$username'" >> JupyterDirectory/BashConfig/bashConfig.txt
	        	read -p "Enter your email associated with your Github account: " email
	        	echo "userEmail='$email'" >> JupyterDirectory/BashConfig/bashConfig.txt
	        	read -p "Enter your Personal Access Token: " personalAccessToken
         		echo "PAT='$personalAccessToken'" >> JupyterDirectory/BashConfig/bashConfig.txt
	        	echo "$personalAccessToken" > JupyterDirectory/BashConfig/PersonalAccessToken.txt
	        	echo ""

		fi

		#Back to Main Menu
		if [ $optionsChoice = 3 ]; then
			optionsMenu=0
			initialChoice=100
		fi
	done

fi

###############################################################################
#5)Exit
###############################################################################

if [ $initialChoice = 5 ]; then
	echo "Closing....."
	sleep 3
	kill -9 $PPID
fi
echo ""
echo "End of program"
echo ""
done

echo "Closing....."
sleep 3
kill -9 $PPID
