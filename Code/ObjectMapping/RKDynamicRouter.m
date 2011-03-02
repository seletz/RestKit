//
//  RKDynamicRouter.m
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKDynamicRouter.h"
#import "RKDynamicRouter.h"
#import "NSDictionary+RKRequestSerialization.h"

@implementation RKDynamicRouter

- (id)init {
	if (self = [super init]) {
		_routes = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[_routes release];
	[super dealloc];
}

- (void)routeClass:(Class)class toResourcePath:(NSString*)resourcePath forMethodName:(NSString*)methodName {
	NSString* className = NSStringFromClass(class);
	if (nil == [_routes objectForKey:className]) {
		NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
		[_routes setObject:dictionary forKey:className];		 
	}
	
	NSMutableDictionary* classRoutes = [_routes objectForKey:className];
	if ([classRoutes objectForKey:methodName]) {
		[NSException raise:nil format:@"A route has already been registered for class '%@' and HTTP method '%@'", className, methodName];
	}
	
	[classRoutes setValue:resourcePath forKey:methodName];
}

// TODO: Should be RKStringFromRequestMethod and RKRequestMethodFromString
- (NSString*)HTTPVerbForMethod:(RKRequestMethod)method {
	switch (method) {
		case RKRequestMethodGET:
			return @"GET";
			break;
		case RKRequestMethodPOST:
			return @"POST";
			break;
		case RKRequestMethodPUT:
			return @"PUT";
			break;
		case RKRequestMethodDELETE:
			return @"DELETE";
			break;
		default:
			return nil;
			break;
	}
}

// Public

- (void)routeClass:(Class<RKObjectMappable>)class toResourcePath:(NSString*)resourcePath {
	[self routeClass:class toResourcePath:resourcePath forMethodName:@"ANY"];
}

- (void)routeClass:(Class)class toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method {
	NSString* methodName = [self HTTPVerbForMethod:method];
	[self routeClass:class toResourcePath:resourcePath forMethodName:methodName];
}

#pragma mark RKRouter

- (NSString*)resourcePathForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method {
	NSLog(@"%s: object=%@", __func__, object);
	NSLog(@"%s: method=%@", __func__, method);
	
	NSString* methodName = [self HTTPVerbForMethod:method];
	NSString* className  = NSStringFromClass([object class]);
	NSDictionary* classRoutes = [_routes objectForKey:className];
	
	NSString* resourcePath = nil;
	if (resourcePath = [classRoutes objectForKey:methodName]) {
		NSLog(@"%s: resourcePath=%@ for method=%@", __func__, resourcePath, methodName);
		
		return RKMakePathWithObject(resourcePath, object);
	}
	
	if (resourcePath = [classRoutes objectForKey:@"ANY"]) {
		NSLog(@"%s: resourcePath=%@ for ANY", __func__, resourcePath);
		return RKMakePathWithObject(resourcePath, object);
	}
	
	[NSException raise:nil format:@"Unable to find a routable path for object of type '%@' for HTTP Method '%@'", className, methodName];
	
	return nil;
}

- (NSObject<RKRequestSerializable>*)serializationForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method {
	// By default return a form encoded serializable dictionary

	// seletz: return nil if we have a get request
        // see also http://groups.google.com/group/restkit/browse_thread/thread/0ae69c2cc4136ae0/8c2a8cfef9442f0d?show_docid=8c2a8cfef9442f0d
	if (method == RKRequestMethodGET)
		return nil;


	return [object propertiesForSerialization];
}

@end
