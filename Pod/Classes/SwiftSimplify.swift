//
// SwiftSimplify.swift
// Simplify
//
// Created by Daniele Margutti on 11/07/15.
// Copyright (c) 2015 Daniele Margutti. All rights reserved
//
// Web:		http://www.danielemargutti.com
// Mail:	me@danielemargutti.com
// Twitter: http://www.twitter.com/danielemargutti
// GitHub:	http://www.github.com/malcommac
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit


public protocol SimplePoint: Equatable {
    var x: Double { get }
    var y: Double { get }
}


open class SwiftSimplify<T: SimplePoint> {

	/**
	Returns an array of simplified points
	
	- parameter points:      An array of points of (maybe CGPoint or CLLocationCoordinate2D points)
	- parameter tolerance:   Affects the amount of simplification (in the same metric as the point coordinates)
	- parameter highQuality: Excludes distance-based preprocessing step which leads to highest quality simplification but runs ~10-20 times slower.
	
	- returns: Returns an array of simplified points
	*/
	open class func simplify(_ points: [T], tolerance: Double = 1.0, highQuality: Bool = false) -> [T] {
		if points.count == 2 {
			return points
		}
		// both algorithms combined for awesome performance
		let sqTolerance = tolerance*tolerance
		var result = (highQuality == true ? points : simplifyRadialDistance(points, tolerance: sqTolerance))
		result = simplifyDouglasPeucker(result, tolerance: sqTolerance)
		return result
	}
	
	
    // MARK: - private
    
    
    private class func simplifyRadialDistance(_ points: [T], tolerance: Double) -> [T] {
		var prevPoint = points.first!
		var newPoints = [prevPoint]
		var point = points[1]
		
		for idx in 1 ..< points.count {
			point = points[idx]
			let distance = getSqDist(point, pointB: prevPoint)
			if distance > tolerance {
				newPoints.append(point)
				prevPoint = point
			}
		}
		
		if prevPoint != point {
			newPoints.append(point)
		}
		
		return newPoints
	}
	
	
    private class func simplifyDouglasPeucker(_ points: [T], tolerance: Double) -> [T] {
		// simplification using Ramer-Douglas-Peucker algorithm
		let last: Int = points.count - 1
		var simplified: [T] = [points.first!]
		simplifyDPStep(points, first: 0, last: last, tolerance: tolerance, simplified: &simplified)
		simplified.append(points[last])
		return simplified
	}
	
	
    private class func simplifyDPStep(_ points: [T], first: Int, last: Int, tolerance: Double, simplified: inout [T]) {
		var maxSqDistance = tolerance
		var index = 0
		
		for i in first + 1 ..< last {
			let sqDist = getSQSegDist(point: points[i], point1: points[first], point2: points[last])
			if sqDist > maxSqDistance {
				index = i
				maxSqDistance = sqDist
			}
		}
		
		if maxSqDistance > tolerance {
			if index - first > 1 {
				simplifyDPStep(points, first: first, last: index, tolerance: tolerance, simplified: &simplified)
			}
			simplified.append(points[index])
			if last - index > 1 {
				simplifyDPStep(points, first: index, last: last, tolerance: tolerance, simplified: &simplified)
			}
		}
	}
	
	
    private class func getSQSegDist(point p: T, point1 p1: T, point2 p2: T) -> Double {
		// square distance from a point to a segment
		var point = p
		var point1 = p1
		var point2 = p2
		var x = point1.x
		var y = point1.y
		var dx = point2.x - x
		var dy = point2.y - y
		
		if dx != 0 || dy != 0 {
			let t = ( (point.x - x) * dx + (point.y - y) * dy ) / ( (dx * dx) + (dy * dy) )
			if t > 1 {
				x = point2.x
				y = point2.y
			} else if t > 0 {
				x += dx * t
				y += dy * t
			}
		}
		
		dx = point.x - x
		dy = point.y - y
		
		return (dx * dx) + (dy * dy)
	}
	
	
    private class func getSqDist(_ pointA: T, pointB: T) -> Double {
		// square distance between 2 points
        let dx = pointA.x - pointB.x
        let dy = pointA.y - pointB.y
        return (dx * dx) + (dy * dy)
	}
}
