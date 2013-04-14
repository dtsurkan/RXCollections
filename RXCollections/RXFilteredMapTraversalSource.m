//  RXFilteredMapTraversalSource.m
//  Created by Rob Rix on 2013-04-14.
//  Copyright (c) 2013 Rob Rix. All rights reserved.

#import "RXFilteredMapTraversalSource.h"

@interface RXFilteredMapTraversalSource ()
@property (nonatomic, strong, readwrite) id<RXTraversal> traversal;
@property (nonatomic, copy, readwrite) RXFilterBlock filter;
@property (nonatomic, copy, readwrite) RXMapBlock map;
@end

@implementation RXFilteredMapTraversalSource

+(instancetype)sourceWithTraversal:(id<RXTraversal>)traversal filter:(RXFilterBlock)filter map:(RXMapBlock)map {
	RXFilteredMapTraversalSource *source = [self new];
	source.traversal = traversal;
	source.filter = filter;
	source.map = map;
	return source;
}


-(void)refillTraversal:(id<RXRefillableTraversal>)traversal {
	[traversal refillWithBlock:^{
		bool exhausted = ((RXTraversal *)self.traversal).isExhausted;
		if (!exhausted) {
			id each = [(RXTraversal *)self.traversal consume];
			if(!self.filter || self.filter(each))
				[traversal produce:self.map? self.map(each) : each];
		}
		return exhausted;
	}];
}

@end
