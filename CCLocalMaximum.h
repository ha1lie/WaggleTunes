#import <Foundation/Foundation.h>

// Local maxima as found during the image analysis. We need this class for ordering by cell hit count.
@interface CCLocalMaximum : NSObject

// Hit count of the cell
@property (assign, nonatomic) unsigned int hitCount;

// Linear index of the cell
@property (assign, nonatomic) unsigned int cellIndex;

// Average color of cell
@property (assign, nonatomic) double red;
@property (assign, nonatomic) double green;
@property (assign, nonatomic) double blue;

// Maximum color component value of average color 
@property (assign, nonatomic) double brightness;

@end