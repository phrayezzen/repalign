import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { AppModule } from '../../app.module';
import { CongressApiService } from '../../congress/congress-api.service';
import { Repository, DataSource } from 'typeorm';
import { Bill, BillCategory } from '../../congress/entities/bill.entity';

const logger = new Logger('SeedBills');

// Map bill titles/subjects to categories
function categorizeBill(title: string): BillCategory {
  const titleLower = title.toLowerCase();

  if (titleLower.includes('climate') || titleLower.includes('environment') || titleLower.includes('energy')) {
    return BillCategory.CLIMATE;
  }
  if (titleLower.includes('health') || titleLower.includes('medical') || titleLower.includes('medicare') || titleLower.includes('medicaid')) {
    return BillCategory.HEALTHCARE;
  }
  if (titleLower.includes('infrastructure') || titleLower.includes('transportation') || titleLower.includes('roads') || titleLower.includes('bridges')) {
    return BillCategory.INFRASTRUCTURE;
  }
  if (titleLower.includes('education') || titleLower.includes('school') || titleLower.includes('student')) {
    return BillCategory.EDUCATION;
  }
  if (titleLower.includes('economy') || titleLower.includes('tax') || titleLower.includes('budget') || titleLower.includes('finance')) {
    return BillCategory.ECONOMY;
  }
  if (titleLower.includes('defense') || titleLower.includes('military') || titleLower.includes('security') || titleLower.includes('armed forces')) {
    return BillCategory.DEFENSE;
  }
  if (titleLower.includes('social') || titleLower.includes('welfare') || titleLower.includes('benefits')) {
    return BillCategory.SOCIAL_SERVICES;
  }

  // Default to Economy for uncategorized bills
  return BillCategory.ECONOMY;
}

async function bootstrap() {
  logger.log('Starting bills seeding process...');

  const app = await NestFactory.createApplicationContext(AppModule);
  const congressApi = app.get(CongressApiService);
  const dataSource = app.get(DataSource);
  const billRepository: Repository<Bill> = dataSource.getRepository(Bill);

  try {
    // Fetch bills from the current Congress (119th) and previous (118th)
    const currentCongress = 119;
    const previousCongress = 118;

    logger.log(`Fetching bills from Congress ${currentCongress}...`);
    const currentBills = await congressApi.getAllBills(currentCongress);

    logger.log(`Fetching bills from Congress ${previousCongress}...`);
    const previousBills = await congressApi.getAllBills(previousCongress);

    const allBills = [...currentBills, ...previousBills];
    logger.log(`Fetched ${allBills.length} total bills from API`);

    let added = 0;
    let updated = 0;
    let skipped = 0;

    for (const apiBill of allBills) {
      try {
        // Build Congress bill ID (e.g., "H.R. 1234" or "S. 5678")
        const billType = apiBill.type?.toUpperCase() || 'UNKNOWN';
        const billNumber = apiBill.number || '0';
        const congressBillId = `${billType} ${billNumber}`;

        // Check if bill already exists
        let bill = await billRepository.findOne({
          where: { congressBillId },
        });

        // Extract title and date
        const title = apiBill.title || 'Untitled Bill';
        const dateVoted = apiBill.latestAction?.actionDate
          ? new Date(apiBill.latestAction.actionDate)
          : new Date();

        // Categorize the bill
        const category = categorizeBill(title);

        // Extract URL
        const congressUrl = apiBill.url || null;

        if (bill) {
          // Update existing bill
          bill.title = title;
          bill.billDescription = apiBill.latestAction?.text || 'No description available';
          bill.category = category;
          bill.dateVoted = dateVoted;
          bill.congressUrl = congressUrl;

          await billRepository.save(bill);
          updated++;
        } else {
          // Create new bill
          bill = billRepository.create({
            congressBillId,
            title,
            billDescription: apiBill.latestAction?.text || 'No description available',
            category,
            dateVoted,
            congressUrl,
            isAlignedWithUser: false, // Default to false, will be calculated based on user preferences
            amount: null, // Will be extracted from bill details if available
          });

          await billRepository.save(bill);
          added++;
        }

        if ((added + updated) % 100 === 0) {
          logger.log(`Progress: ${added + updated}/${allBills.length} processed`);
        }
      } catch (error) {
        logger.error(`Error processing bill ${apiBill.number}: ${error.message}`);
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
