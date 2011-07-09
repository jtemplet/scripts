#!/bin/bash

# This script takes an Android project and makes it 
# an Eclipse Android project

PROJ_FILE=".project"
CLASSPATH_FILE=".classpath"
workingdir=$(pwd)
project=${workingdir##*/}

##################################
#
# Creates .project file
#
##################################

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $PROJ_FILE
echo "<projectDescription>" >> $PROJ_FILE
echo "<name>$project</name>" >> $PROJ_FILE
echo "	<comment></comment>" >> $PROJ_FILE
echo "<projects>" >> $PROJ_FILE
echo "</projects>" >> $PROJ_FILE
echo "<buildSpec>" >> $PROJ_FILE
echo "	<buildCommand>" >> $PROJ_FILE
echo "		<name>com.android.ide.eclipse.adt.ResourceManagerBuilder</name>" >> $PROJ_FILE
echo "			<arguments>" >> $PROJ_FILE
echo "			</arguments>" >> $PROJ_FILE
echo "	</buildCommand>" >> $PROJ_FILE
echo "	<buildCommand>" >> $PROJ_FILE
echo "		<name>com.android.ide.eclipse.adt.PreCompilerBuilder</name>" >> $PROJ_FILE
echo "			<arguments>" >> $PROJ_FILE
echo "			</arguments>" >> $PROJ_FILE
echo "	</buildCommand>" >> $PROJ_FILE
echo "	<buildCommand>" >> $PROJ_FILE
echo "		<name>org.eclipse.jdt.core.javabuilder</name>" >> $PROJ_FILE
echo "			<arguments>" >> $PROJ_FILE
echo "			</arguments>" >> $PROJ_FILE
echo "	</buildCommand>" >> $PROJ_FILE
echo "	<buildCommand>" >> $PROJ_FILE
echo "		<name>com.android.ide.eclipse.adt.ApkBuilder</name>" >> $PROJ_FILE
echo "			<arguments>" >> $PROJ_FILE
echo "			</arguments>" >> $PROJ_FILE
echo "	</buildCommand>" >> $PROJ_FILE
echo "</buildSpec>" >> $PROJ_FILE
echo "<natures>" >> $PROJ_FILE
echo "		<nature>com.android.ide.eclipse.adt.AndroidNature</nature>" >> $PROJ_FILE
echo "		<nature>org.eclipse.jdt.core.javanature</nature>" >> $PROJ_FILE
echo "</natures>" >> $PROJ_FILE
echo "</projectDescription>" >> $PROJ_FILE

##################################
#
# Creates .classpath file
#
##################################
echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" > $CLASSPATH_FILE
echo "<classpath> " >> $CLASSPATH_FILE
echo "  <classpathentry kind=\"src\" path=\"src\"/>" >> $CLASSPATH_FILE
echo "  <classpathentry kind=\"src\" path=\"gen\"/>" >> $CLASSPATH_FILE
echo "  <classpathentry kind=\"con\" path=\"com.android.ide.eclipse.adt.ANDROID_FRAMEWORK\"/>" >> $CLASSPATH_FILE
echo "  <classpathentry kind=\"output\" path=\"bin\"/>" >> $CLASSPATH_FILE
echo "</classpath> " >> $CLASSPATH_FILE
