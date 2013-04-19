//  RXGenerator.m
//  Created by Rob Rix on 2013-03-09.
//  Copyright (c) 2013 Rob Rix. All rights reserved.

#import "RXFold.h"
#import "RXGenerator.h"
#import "RXTuple.h"
#import "RXFastEnumerationState.h"

#import <Lagrangian/Lagrangian.h>

@l3_suite("RXGenerator");

@interface RXGeneratorTraversalSource : NSObject <RXGenerator, RXTraversalSource, RXTraversable>

+(instancetype)generatorWithBlock:(RXGeneratorBlock)block;
+(instancetype)generatorWithContext:(id<NSObject, NSCopying>)context block:(RXGeneratorBlock)block;

@property (nonatomic, readonly) id nextObject;
@property (nonatomic, getter = isComplete, readwrite) bool complete;
@property (nonatomic, copy, readonly) RXGeneratorBlock block;
@end

@implementation RXGeneratorTraversalSource

@synthesize context = _context;

#pragma mark Construction

+(instancetype)generatorWithBlock:(RXGeneratorBlock)block {
	return [self generatorWithContext:nil block:block];
}

+(instancetype)generatorWithContext:(id<NSObject, NSCopying>)context block:(RXGeneratorBlock)block {
	return [[self alloc] initWithContext:context block:block];
}

-(instancetype)initWithContext:(id<NSObject, NSCopying>)context block:(RXGeneratorBlock)block {
	if ((self = [super init])) {
		_context = context;
		_block = [block copy];
	}
	return self;
}


static RXGeneratorBlock RXFibonacciGenerator() {
	return [^(RXGeneratorTraversalSource *self) {
		NSNumber *previous = self.context[1], *next = @([self.context[0] unsignedIntegerValue] + [previous unsignedIntegerValue]);
		self.context = (id)[RXTuple tupleWithArray:@[previous, next]];
		return previous;
	} copy];
}

@l3_test("enumerates generated objects") {
	NSMutableArray *series = [NSMutableArray new];
	for (NSNumber *number in [RXGeneratorTraversalSource generatorWithContext:[RXTuple tupleWithArray:@[@0, @1]] block:RXFibonacciGenerator()].traversal) {
		[series addObject:number];
		if (series.count == 12)
			break;
	}
	l3_assert(series, (@[@1, @1, @2, @3, @5, @8, @13, @21, @34, @55, @89, @144]));
}

static RXGeneratorBlock RXIntegerGenerator(NSUInteger n) {
	return [^(RXGeneratorTraversalSource *self) {
		NSUInteger current = [(NSNumber *)self.context unsignedIntegerValue];
		self.context = @(current + 1);
		if (current >= n)
			[self complete];
		return @(current);
	} copy];
}

@l3_test("stops enumerating when requested to by the generator") {
	NSArray *integers = RXConstructArray([RXGeneratorTraversalSource generatorWithBlock:RXIntegerGenerator(3)].traversal);
	l3_assert(integers, (@[@0, @1, @2, @3]));
}


-(id<RXTraversal>)traversal {
	return [RXTraversal traversalWithSource:self];
}


-(id)nextObject {
	return self.block(self);
}

-(bool)isComplete {
	return _complete;
}

-(void)complete {
	self.complete = YES;
}

-(void)refillTraversal:(id<RXRefillableTraversal>)traversal {
	[traversal refillWithBlock:^bool{
		[traversal produce:[self nextObject]];
		return self.isComplete;
	}];
}

@end
