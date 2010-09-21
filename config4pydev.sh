#!/bin/bash

PROJ_FILE=".project"
PYDEV_FILE=".pydevproject"
SRC_DIR="src"
RSRC_DIR="resources"
workingdir=$(pwd)
project=${workingdir##*/}

# Create a src directory
if [ -a $SRC_DIR ]; then
  echo "'src' already directory exists"
else
  mkdir $SRC_DIR
fi

# Create a resources directory
if [ -a $RSRC_DIR ]; then
  echo "'resources' already directory exists"
else
  mkdir $RSRC_DIR
fi

# Move all the python files into the src directory
files=$(ls *.py 2> /dev/null | wc -l)
if [ "$files" != "0" ]; then
  mv *.py src
fi

# Remove all the *.pyc files
files=$(ls *.pyc 2> /dev/null | wc -l)
if [ "$files" != "0" ]; then
  rm *.pyc
fi

# Move all directories (except src and resources) into src
for f in *
do
  if [ -d $f ]; then
    if [ $f != $SRC_DIR ] && [ $f != $RSRC_DIR ]; then
      mv $f $SRC_DIR 
    fi
  fi
done

##################################
#
# Creates .project file
#
##################################

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $PROJ_FILE
echo "<projectDescription>" >> $PROJ_FILE
echo "<name>$project</name>" >> $PROJ_FILE
echo "	<comment></comment>" >> $PROJ_FILE
echo 	"<projects>" >> $PROJ_FILE
echo	"</projects>" >> $PROJ_FILE
echo	"<buildSpec>" >> $PROJ_FILE
echo	"	<buildCommand>" >> $PROJ_FILE
echo	"		<name>org.python.pydev.PyDevBuilder</name>" >> $PROJ_FILE
echo	"			<arguments>" >> $PROJ_FILE
echo	"			</arguments>" >> $PROJ_FILE
echo	"		</buildCommand>" >> $PROJ_FILE
echo	"	</buildSpec>" >> $PROJ_FILE
echo	"	<natures>" >> $PROJ_FILE
echo	"		<nature>org.python.pydev.pythonNature</nature>" >> $PROJ_FILE
echo	"		<nature>org.python.pydev.django.djangoNature</nature>" >> $PROJ_FILE
echo	"	</natures>" >> $PROJ_FILE
echo "</projectDescription>" >> $PROJ_FILE

##################################
#
# Creates .pydevproject file
#
##################################
echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>" > $PYDEV_FILE
echo "<?eclipse-pydev version=\"1.0\"?>" >> $PYDEV_FILE
echo "" >> $PYDEV_FILE
echo "<pydev_project> " >> $PYDEV_FILE
echo "<pydev_property name=\"org.python.pydev.PYTHON_PROJECT_INTERPRETER\">Default</pydev_property> " >> $PYDEV_FILE
echo "<pydev_property name=\"org.python.pydev.PYTHON_PROJECT_VERSION\">python 2.7</pydev_property> " >> $PYDEV_FILE
echo "<pydev_variables_property name=\"org.python.pydev.PROJECT_VARIABLE_SUBSTITUTION\"> " >> $PYDEV_FILE
echo "<key>DJANGO_MANAGE_LOCATION</key> " >> $PYDEV_FILE
echo "<value>src/$project/manage.py</value> " >> $PYDEV_FILE
echo "</pydev_variables_property> " >> $PYDEV_FILE
echo "<pydev_pathproperty name=\"org.python.pydev.PROJECT_SOURCE_PATH\"> " >> $PYDEV_FILE
echo "<path>/$project/src</path> " >> $PYDEV_FILE
echo "</pydev_pathproperty> " >> $PYDEV_FILE
echo "</pydev_project> " >> $PYDEV_FILE
