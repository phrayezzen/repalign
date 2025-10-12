import { ApiProperty } from '@nestjs/swagger';

export enum FeedItemType {
  POST = 'post',
  EVENT = 'event',
  PETITION = 'petition',
}

export class FeedItemDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ enum: FeedItemType })
  type: FeedItemType;

  @ApiProperty({ required: false })
  title?: string;

  @ApiProperty()
  content: string;

  @ApiProperty()
  authorId: string;

  @ApiProperty()
  authorName: string;

  @ApiProperty({ required: false })
  authorAvatar?: string;

  @ApiProperty()
  createdAt: Date;

  // Event-specific fields
  @ApiProperty({ required: false })
  eventDate?: Date;

  @ApiProperty({ required: false })
  eventLocation?: string;

  @ApiProperty({ required: false })
  eventType?: string;

  @ApiProperty({ required: false })
  eventEndDate?: Date;

  @ApiProperty({ required: false })
  eventAddress?: string;

  @ApiProperty({ required: false })
  eventDuration?: string;

  @ApiProperty({ required: false })
  eventFormat?: string;

  @ApiProperty({ required: false })
  eventNote?: string;

  @ApiProperty({ required: false })
  eventDetailedDescription?: string;

  @ApiProperty({ required: false })
  heroImageUrl?: string;

  @ApiProperty({ required: false })
  organizerFollowers?: number;

  @ApiProperty({ required: false })
  organizerEventsCount?: number;

  @ApiProperty({ required: false })
  organizerYearsActive?: number;

  // Petition-specific fields
  @ApiProperty({ required: false })
  petitionSignatures?: number;

  @ApiProperty({ required: false })
  petitionTargetSignatures?: number;

  @ApiProperty({ required: false })
  petitionDeadline?: Date;

  @ApiProperty({ required: false })
  petitionCategory?: string;

  // Post-specific fields
  @ApiProperty({ required: false })
  postType?: string;

  @ApiProperty({ required: false })
  imageUrl?: string;

  @ApiProperty({ required: false })
  attachmentUrls?: string[];

  @ApiProperty({ required: false })
  tags?: string[];

  // Engagement metrics
  @ApiProperty({ default: 0 })
  likeCount?: number;

  @ApiProperty({ default: 0 })
  commentCount?: number;

  @ApiProperty({ default: 0 })
  shareCount?: number;
}