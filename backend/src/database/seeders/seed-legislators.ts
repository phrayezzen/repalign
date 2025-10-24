import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { AppModule } from '../../app.module';
import { CongressApiService } from '../../congress/congress-api.service';
import { Repository, DataSource } from 'typeorm';
import { Legislator } from '../../congress/entities/legislator.entity';
import { Party } from '../../users/entities/legislator-profile.entity';

const logger = new Logger('SeedLegislators');

async function bootstrap() {
  logger.log('Starting legislators seeding process...');

  const app = await NestFactory.createApplicationContext(AppModule);
  const congressApi = app.get(CongressApiService);
  const dataSource = app.get(DataSource);
  const legislatorRepository: Repository<Legislator> = dataSource.getRepository(Legislator);

  try {
    logger.log('Fetching current members from Congress.gov API...');
    const members = await congressApi.getCurrentMembers();

    logger.log(`Fetched ${members.length} members from API`);

    let added = 0;
    let updated = 0;
    let skipped = 0;

    for (const member of members) {
      try {
        // Check if legislator already exists
        let legislator = await legislatorRepository.findOne({
          where: { bioguideId: member.bioguideId },
        });

        // Calculate years in office
        const yearsInOffice = congressApi.calculateYearsInOffice(member.termStart);

        if (legislator) {
          // Update existing legislator
          legislator.firstName = member.firstName;
          legislator.lastName = member.lastName;
          legislator.party = member.party;
          legislator.state = member.state;
          legislator.district = member.district;
          legislator.chamber = member.chamber;
          legislator.photoUrl = member.photoUrl;
          legislator.yearsInOffice = yearsInOffice;
          legislator.initials = `${member.firstName.charAt(0)}${member.lastName.charAt(0)}`;

          await legislatorRepository.save(legislator);
          updated++;
        } else {
          // Create new legislator
          legislator = legislatorRepository.create({
            bioguideId: member.bioguideId,
            firstName: member.firstName,
            lastName: member.lastName,
            party: member.party,
            state: member.state,
            district: member.district,
            chamber: member.chamber,
            photoUrl: member.photoUrl,
            yearsInOffice,
            initials: `${member.firstName.charAt(0)}${member.lastName.charAt(0)}`,
            followerCount: 0,
          });

          await legislatorRepository.save(legislator);
          added++;
        }

        if ((added + updated) % 50 === 0) {
          logger.log(`Progress: ${added + updated}/${members.length} processed`);
        }
      } catch (error) {
        logger.error(`Error processing member ${member.bioguideId}: ${error.message}`);
        skipped++;
      }
    }

    logger.log('Seeding completed successfully!');
    logger.log(`Added: ${added}, Updated: ${updated}, Skipped: ${skipped}`);
  } catch (error) {
    logger.error('Seeding failed:', error.stack);
    process.exit(1);
  } finally {
    await app.close();
  }
}

bootstrap();
