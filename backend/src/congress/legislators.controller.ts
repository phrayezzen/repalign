import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { LegislatorsService } from './legislators.service';
import { FindLegislatorsDto } from './dto/find-legislators.dto';
import { Legislator } from './entities/legislator.entity';
import { Public } from '../auth/decorators/public.decorator';

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
  async findAll(@Query() query: FindLegislatorsDto) {
    return this.legislatorsService.findAll(query);
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

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific legislator by ID' })
  @ApiParam({ name: 'id', description: 'Legislator UUID' })
  @ApiResponse({
    status: 200,
    description: 'The legislator',
    type: Legislator,
  })
  @ApiResponse({ status: 404, description: 'Legislator not found' })
  async findOne(@Param('id') id: string) {
    return this.legislatorsService.findOne(id);
  }
}