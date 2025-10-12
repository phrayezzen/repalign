import { ApiProperty } from '@nestjs/swagger';
import { FeedItemDto } from './feed-item.dto';

export class FeedResponseDto {
  @ApiProperty({ type: [FeedItemDto] })
  items: FeedItemDto[];

  @ApiProperty()
  total: number;

  @ApiProperty()
  page: number;

  @ApiProperty()
  limit: number;

  @ApiProperty()
  hasMore: boolean;
}