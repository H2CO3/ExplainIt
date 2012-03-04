all:
	gcc -isysroot /User/sysroot -Wall -std=gnu99 -c -o ExplainIt.o ExplainIt.m
	gcc -isysroot /User/sysroot -w -dynamiclib -lobjc -lsubstrate -framework Foundation -framework UIKit -framework BingTranslate -o ExplainIt.dylib ExplainIt.o
	cp ExplainIt.dylib ExplainIt.plist /Library/MobileSubstrate/DynamicLibraries

