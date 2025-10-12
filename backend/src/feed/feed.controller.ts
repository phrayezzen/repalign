import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { Public } from '../auth/decorators/public.decorator';
import { FeedService } from './feed.service';
import { FeedQueryDto } from './dto/feed-query.dto';
import { FeedResponseDto } from './dto/feed-response.dto';

@ApiTags('Feed')
@Controller('feed')
export class FeedController {
  constructor(private readonly feedService: FeedService) {}

  @Get()
  @Public()
  @ApiOperation({ summary: 'Get unified feed with posts, events, and petitions' })
  @ApiResponse({
    status: 200,
    description: 'Feed retrieved successfully',
    type: FeedResponseDto,
  })
  async getFeed(@Query() query: FeedQueryDto): Promise<FeedResponseDto> {
    return this.feedService.getFeed(query);
  }
}