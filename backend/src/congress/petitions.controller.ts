import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { PetitionsService } from './petitions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Public } from '../auth/decorators/public.decorator';
import { PetitionQueryDto } from './dto/petition-query.dto';
import { CreatePetitionDto } from './dto/create-petition.dto';
import { SignPetitionDto } from './dto/sign-petition.dto';
import { PetitionDto, PetitionListResponseDto } from './dto/petition-response.dto';

@ApiTags('Petitions')
@Controller('congress/petitions')
export class PetitionsController {
  constructor(private readonly petitionsService: PetitionsService) {}

  @Get()
  @Public()
  @ApiOperation({ summary: 'Get all petitions with optional filters' })
  @ApiResponse({
    status: 200,
    description: 'Petitions retrieved successfully',
    type: PetitionListResponseDto,
  })
  async findAll(
    @Query() query: PetitionQueryDto,
    @CurrentUser() user?: any,
  ): Promise<PetitionListResponseDto> {
    return this.petitionsService.findAll(query, user?.id);
  }

  @Get(':id')
  @Public()
  @ApiOperation({ summary: 'Get a single petition by ID' })
  @ApiResponse({
    status: 200,
    description: 'Petition retrieved successfully',
    type: PetitionDto,
  })
  @ApiResponse({ status: 404, description: 'Petition not found' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser() user?: any,
  ): Promise<PetitionDto> {
    return this.petitionsService.findOne(id, user?.id);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new petition' })
  @ApiResponse({
    status: 201,
    description: 'Petition created successfully',
    type: PetitionDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid input' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async create(
    @Body() createPetitionDto: CreatePetitionDto,
    @CurrentUser() user: any,
  ): Promise<PetitionDto> {
    return this.petitionsService.create(createPetitionDto, user.id);
  }

  @Post(':id/sign')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Sign a petition' })
  @ApiResponse({
    status: 201,
    description: 'Petition signed successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid request or petition cannot be signed' })
  @ApiResponse({ status: 404, description: 'Petition not found' })
  @ApiResponse({ status: 409, description: 'User already signed this petition' })
  async sign(
    @Param('id') id: string,
    @Body() signDto: SignPetitionDto,
    @CurrentUser() user: any,
  ): Promise<{ message: string; currentSignatures: number }> {
    return this.petitionsService.sign(id, user.id, signDto);
  }

  @Delete(':id/sign')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove signature from a petition' })
  @ApiResponse({
    status: 200,
    description: 'Signature removed successfully',
  })
  @ApiResponse({ status: 404, description: 'Petition or signature not found' })
  async unsign(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ): Promise<{ message: string; currentSignatures: number }> {
    return this.petitionsService.unsign(id, user.id);
  }

  @Get(':id/signatures')
  @Public()
  @ApiOperation({ summary: 'Get public signatures for a petition' })
  @ApiResponse({
    status: 200,
    description: 'Signatures retrieved successfully',
  })
  async getSignatures(@Param('id') id: string): Promise<any[]> {
    return this.petitionsService.getSignatures(id);
  }
}
