import { Controller, Get, Post, Delete, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam, ApiBearerAuth } from '@nestjs/swagger';
import { LegislatorsService } from './legislators.service';
import { FindLegislatorsDto } from './dto/find-legislators.dto';
import { Legislator } from './entities/legislator.entity';
import { Public } from '../auth/decorators/public.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('congress')
@Controller('legislators')
export class LegislatorsController {
  constructor(private readonly legislatorsService: LegislatorsService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Get all legislators with filtering and pagination' })
  @ApiResponse({
    status: 200,
    description: 'List of legislators with pagination info',
    schema: {
      type: 'object',
      properties: {
        legislators: {
          type: 'array',
          items: { $ref: '#/components/schemas/Legislator' },
        },
        total: { type: 'number' },
        limit: { type: 'number' },
        offset: { type: 'number' },
        hasMore: { type: 'boolean' },
      },
    },
  })
  async findAll(@Query() query: FindLegislatorsDto, @CurrentUser() user?: any) {
    return this.legislatorsService.findAll(query, user?.id);
  }

  @Public()
  @Get('stats')
  @ApiOperation({ summary: 'Get statistics about legislators' })
  @ApiResponse({
    status: 200,
    description: 'Statistics about legislators',
    schema: {
      type: 'object',
      properties: {
        total: { type: 'number' },
        senators: { type: 'number' },
        representatives: { type: 'number' },
        byParty: { type: 'object' },
      },
    },
  })
  async getStats() {
    return this.legislatorsService.getStats();
  }

  @Get('states/:state')
  @ApiOperation({ summary: 'Get all legislators from a specific state' })
  @ApiParam({ name: 'state', description: 'Two-letter state code' })
  @ApiResponse({
    status: 200,
    description: 'List of legislators from the state',
    type: [Legislator],
  })
  async findByState(@Param('state') state: string) {
    return this.legislatorsService.findByState(state);
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get a specific legislator by ID' })
  @ApiParam({ name: 'id', description: 'Legislator UUID' })
  @ApiResponse({
    status: 200,
    description: 'The legislator with top donors and recent votes',
    type: Legislator,
  })
  @ApiResponse({ status: 404, description: 'Legislator not found' })
  async findOne(@Param('id') id: string, @CurrentUser() user?: any) {
    return this.legislatorsService.findOne(id, user?.id);
  }

  @Post(':id/follow')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Follow a legislator' })
  @ApiParam({ name: 'id', description: 'Legislator UUID' })
  @ApiResponse({
    status: 201,
    description: 'Successfully followed legislator',
    schema: {
      type: 'object',
      properties: {
        message: { type: 'string' },
        followerCount: { type: 'number' },
      },
    },
  })
  @ApiResponse({ status: 404, description: 'Legislator not found' })
  @ApiResponse({ status: 409, description: 'Already following' })
  async followLegislator(@Param('id') id: string, @CurrentUser() user: any) {
    return this.legislatorsService.followLegislator(id, user.id);
  }

  @Delete(':id/follow')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Unfollow a legislator' })
  @ApiParam({ name: 'id', description: 'Legislator UUID' })
  @ApiResponse({
    status: 200,
    description: 'Successfully unfollowed legislator',
    schema: {
      type: 'object',
      properties: {
        message: { type: 'string' },
        followerCount: { type: 'number' },
      },
    },
  })
  @ApiResponse({ status: 404, description: 'Legislator or follow not found' })
  async unfollowLegislator(@Param('id') id: string, @CurrentUser() user: any) {
    return this.legislatorsService.unfollowLegislator(id, user.id);
  }

  @Public()
  @Get(':id/donors')
  @ApiOperation({ summary: 'Get paginated donors for a legislator' })
  @ApiParam({ name: 'id', description: 'Legislator UUID' })
  @ApiResponse({
    status: 200,
    description: 'Paginated list of donors',
    schema: {
      type: 'object',
      properties: {
        donors: { type: 'array' },
        total: { type: 'number' },
        limit: { type: 'number' },
        offset: { type: 'number' },
        hasMore: { type: 'boolean' },
      },
    },
  })
  async getDonors(
    @Param('id') id: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
    @Query('type') type?: string,
  ) {
    return this.legislatorsService.getDonors(id, {
      limit: limit ? +limit : 50,
      offset: offset ? +offset : 0,
      type,
    });
  }

  @Public()
  @Get(':id/votes')
  @ApiOperation({ summary: 'Get paginated votes for a legislator' })
  @ApiParam({ name: 'id', description: 'Legislator UUID' })
  @ApiResponse({
    status: 200,
    description: 'Paginated list of votes',
    schema: {
      type: 'object',
      properties: {
        votes: { type: 'array' },
        total: { type: 'number' },
        limit: { type: 'number' },
        offset: { type: 'number' },
        hasMore: { type: 'boolean' },
      },
    },
  })
  async getVotes(
    @Param('id') id: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.legislatorsService.getVotes(id, {
      limit: limit ? +limit : 50,
      offset: offset ? +offset : 0,
    });
  }

  @Public()
  @Get(':id/press')
  @ApiOperation({ summary: 'Get paginated press releases for a legislator' })
  @ApiParam({ name: 'id', description: 'Legislator UUID' })
  @ApiResponse({
    status: 200,
    description: 'Paginated list of press releases',
    schema: {
      type: 'object',
      properties: {
        pressReleases: { type: 'array' },
        total: { type: 'number' },
        limit: { type: 'number' },
        offset: { type: 'number' },
        hasMore: { type: 'boolean' },
      },
    },
  })
  async getPressReleases(
    @Param('id') id: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.legislatorsService.getPressReleases(id, {
      limit: limit ? +limit : 50,
      offset: offset ? +offset : 0,
    });
  }
}