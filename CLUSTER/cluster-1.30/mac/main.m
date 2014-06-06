//
//  main.m
//  Cluster 3.0 for Mac OS X
//
//  Created by mdehoon on 17 October 2002.
//  Copyright (c) 2002, Michiel de Hoon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "data.h"
#import "Controller.h"

int main(int argc, const char *argv[])
{
    int result;
    result = NSApplicationMain(argc, argv);
    Free();
    return result;
}
