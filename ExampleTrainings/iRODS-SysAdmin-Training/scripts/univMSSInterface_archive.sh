#!/bin/bash

# based on https://github.com/irods/irods/blob/master/msiExecCmd_bin/univMSSInterface.sh

export USER="christin"
export ARCHIVEADDRESS="archive.surfsara.nl"
export SCPCOMMAND=/usr/bin/scp
export KEY=/var/lib/irods/.ssh/somekey

syncToArch () {
	# <your command or script to copy from cache to MSS> ${1:?} ${2:?} 
	# e.g: /usr/local/bin/rfcp ${1:?} rfioServerFoo:${2:?}
	echo "UNIVMSS ${SCPCOMMAND} -i ${KEY} ${1:?} ${USER}@${ARCHIVEADDRESS}:${2:?}"
	"${SCPCOMMAND}" -i "${KEY}" "${1:?}" "${USER}@${ARCHIVEADDRESS}:${2}"
	return
}

# function for staging a file ${1:?} from the MSS to file ${2:?} on disk
stageToCache () {
	# <your command to stage from MSS to cache> ${1:?} ${2:?}	
	# e.g: /usr/local/bin/rfcp rfioServerFoo:${1:?} ${2:?}
        #op=`which cp`
        #`$op ${1:?} ${2:?}`
        #echo "UNIVMSS $op ${1:?} ${2:?}"
        echo "UNIVMSS ${SCPCOMMAND} -i ${KEY} ${USER}@${ARCHIVEADDRESS}:${1:?} ${2:?}"
        ${SCPCOMMAND} -i ${KEY} ${USER}@${ARCHIVEADDRESS}:${1:?} ${2:?}
	return
}

# function to create a new directory ${1:?} in the MSS logical name space
mkdir () {
	# <your command to make a directory in the MSS> ${1:?}
	# e.g.: /usr/local/bin/rfmkdir -p rfioServerFoo:${1:?}
	#ssh remote-host 'mkdir -p foo/bar/qux'
	echo "UNIVMSS ssh -i ${KEY} ${USER}@${ARCHIVEADDRESS} mkdir -p ${1:?}"
	ssh -i ${KEY} ${USER}@${ARCHIVEADDRESS} "mkdir -p ${1:?}"
	return
}

# function to modify ACLs ${2:?} (octal) in the MSS logical name space for a given directory ${1:?} 
chmod () {
	# <your command to modify ACL> ${2:?} ${1:?}
	# e.g: /usr/local/bin/rfchmod ${2:?} rfioServerFoo:${1:?}
	############
	# LEAVING THE PARAMETERS "OUT OF ORDER" (${2:?} then ${1:?})
	#    because the driver provides them in this order
	# ${2:?} is mode
	# ${1:?} is directory
	############
        #op=`which chmod`
        #`$op ${2:?} ${1:?}`

	echo "UNIVMSS ssh -i ${KEY} ${USER}@${ARCHIVEADDRESS} chmod ${2:?} ${1:?}"
	return
}

# function to remove a file ${1:?} from the MSS
rm () {
	# <your command to remove a file from the MSS> ${1:?}
	# e.g: /usr/local/bin/rfrm rfioServerFoo:${1:?}
    	#op=`which rm`
	#`$op ${1:?}`
	echo "UNIVMSS ssh -i ${KEY} ${USER}@${ARCHIVEADDRESS} rm ${1:?}"
	ssh -i ${KEY} ${USER}@${ARCHIVEADDRESS} "rm ${1:?}"
	return
}

# function to rename a file ${1:?} into ${2:?} in the MSS
mv () {
    	# <your command to rename a file in the MSS> ${1:?} ${2:?}
    	# e.g: /usr/local/bin/rfrename rfioServerFoo:${1:?} rfioServerFoo:${2:?}
    	#op=`which mv`
    	#`$op ${1:?} ${2:?}`
	echo "UNIVMSS ssh -i ${KEY} ${USER}@${ARCHIVEADDRESS} mv ${1:?} ${2:?}"
	ssh -i ${KEY} ${USER}@${ARCHIVEADDRESS} "mv ${1:?} ${2:?}"
    	return
}

# function to do a stat on a file ${1:?} stored in the MSS
stat () {
        #op=`which stat`
	#output=`$op ${1:?}`
	# <your command to retrieve stats on the file> ${1:?}
	# e.g: output=`/usr/local/bin/rfstat rfioServerFoo:${1:?}`
	#error=$?
	#if [ $error != 0 ] # if file does not exist or information not available
	#then
	#	return $error
	#fi
	# parse the output.
	# Parameters to retrieve: device ID of device containing file("device"), 
	#                         file serial number ("inode"), ACL mode in octal ("mode"),
	#                         number of hard links to the file ("nlink"),
	#                         user id of file ("uid"), group id of file ("gid"),
	#                         device id ("devid"), file size ("size"), last access time ("atime"),
	#                         last modification time ("mtime"), last change time ("ctime"),
	#                         block size in bytes ("blksize"), number of blocks ("blkcnt")
	# e.g: device=`echo $output | awk '{print ${3:?}}'`	
	# Note 1: if some of these parameters are not relevant, set them to 0.
	# Note 2: the time should have this format: YYYY-MM-dd-hh.mm.ss with: 
	#                                           YYYY = 1900 to 2xxxx, MM = 1 to 12, dd = 1 to 31,
	#                                           hh = 0 to 24, mm = 0 to 59, ss = 0 to 59

       	# Get the stat info from the remote server 
    	output=`ssh -i ${KEY} ${USER}@${ARCHIVEADDRESS} "stat ${1:?}"`
	#echo $output
	error=$?

	if [ $error != 0 ] # if file does not exist or information not available
        then
                return $error
        fi

    	device=` echo $output | sed -nr 's/.*\<Device: *(\S*)\>.*/\1/p'`
    	inode=`  echo $output | sed -nr 's/.*\<Inode: *(\S*)\>.*/\1/p'`
    	mode=`   echo $output | sed -nr 's/.*\<Access: *\(([0-9]*)\/.*/\1/p'`
    	nlink=`  echo $output | sed -nr 's/.*\<Links: *([0-9]*)\>.*/\1/p'`
    	uid=`    echo $output | sed -nr 's/.*\<Uid: *\( *([0-9]*)\/.*/\1/p'`
    	gid=`    echo $output | sed -nr 's/.*\<Gid: *\( *([0-9]*)\/.*/\1/p'`
    	devid="0"
    	size=`   echo $output | sed -nr 's/.*\<Size: *([0-9]*)\>.*/\1/p'`
    	blksize=`echo $output | sed -nr 's/.*\<IO Block: *([0-9]*)\>.*/\1/p'`
    	blkcnt=` echo $output | sed -nr 's/.*\<Blocks: *([0-9]*)\>.*/\1/p'`
    	atime=`  echo $output | sed -nr 's/.*\<Access: *([0-9]{4,}-[01][0-9]-[0-3][0-9]) *([0-2][0-9]):([0-5][0-9]):([0-6][0-9])\..*/\1-\2.\3.\4/p'`
    	mtime=`  echo $output | sed -nr 's/.*\<Modify: *([0-9]{4,}-[01][0-9]-[0-3][0-9]) *([0-2][0-9]):([0-5][0-9]):([0-6][0-9])\..*/\1-\2.\3.\4/p'`
    	ctime=`  echo $output | sed -nr 's/.*\<Change: *([0-9]{4,}-[01][0-9]-[0-3][0-9]) *([0-2][0-9]):([0-5][0-9]):([0-6][0-9])\..*/\1-\2.\3.\4/p'`
	echo "$device:$inode:$mode:$nlink:$uid:$gid:$devid:$size:$blksize:$blkcnt:$atime:$mtime:$ctime"
	return
}

#############################################
# below this line, nothing should be changed.
#############################################

case "${1:?}" in
	syncToArch ) ${1:?} ${2:?} ${3:?} ;;
	stageToCache ) ${1:?} ${2:?} ${3:?} ;;
	mkdir ) ${1:?} ${2:?} ;;
	chmod ) ${1:?} ${2:?} ${3:?} ;;
	rm ) ${1:?} ${2:?} ;;
	mv ) ${1:?} ${2:?} ${3:?} ;;
	stat ) ${1:?} ${2:?} ;;
esac

exit $?
