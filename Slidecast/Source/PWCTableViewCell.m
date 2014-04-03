//
//  PWCTableViewCell.m
//  Slidecast
//
//  Created by Elliot Soloway on 4/2/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCTableViewCell.h"

@interface PWCTableViewCell()

//add more classes that we would need

@end

@implementation PWCTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
