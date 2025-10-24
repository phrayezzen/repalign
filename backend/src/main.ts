import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import * as compression from 'compression';
import { AppModule } from './app.module';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  try {
    console.log('🔄 Starting RepAlign API...');
    console.log('📦 Node environment:', process.env.NODE_ENV);
    console.log('🗄️  Database URL:', process.env.DATABASE_URL ? 'Set (Railway)' : 'Not set');

    const app = await NestFactory.create(AppModule, {
      logger: ['error', 'warn', 'log', 'debug', 'verbose'],
    });

    console.log('✅ NestFactory created successfully');

    const configService = app.get(ConfigService);
    const port = configService.get('PORT') || 3000;
    const apiPrefix = configService.get('API_PREFIX') || 'api/v1';

    console.log(`🔧 Port: ${port}, API Prefix: ${apiPrefix}`);

    // Security middleware
    app.use(helmet());
    app.use(compression());

    // CORS configuration - Allow all origins for development
    app.enableCors({
      origin: true, // Allow all origins for testing
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'ngrok-skip-browser-warning'],
      exposedHeaders: ['Content-Type', 'Authorization'],
    });

    // Global validation
    app.useGlobalPipes(
      new ValidationPipe({
        transform: true,
        whitelist: true,
        forbidNonWhitelisted: true,
      }),
    );

    // Global logging interceptor
    app.useGlobalInterceptors(new LoggingInterceptor());

    // API prefix
    app.setGlobalPrefix(apiPrefix);

    // Swagger documentation
    if (configService.get('NODE_ENV') !== 'production') {
      const config = new DocumentBuilder()
        .setTitle('RepAlign API')
        .setDescription('Backend API for RepAlign - Civic engagement platform')
        .setVersion('1.0')
        .addBearerAuth()
        .addTag('auth', 'Authentication endpoints')
        .addTag('users', 'User management')
        .addTag('posts', 'Social posts and interactions')
        .addTag('congress', 'Congress data and legislators')
        .addTag('gamification', 'Points, badges, and leaderboards')
        .build();

      const document = SwaggerModule.createDocument(app, config);
      SwaggerModule.setup('docs', app, document);
    }

    console.log(`🎧 Attempting to listen on 0.0.0.0:${port}...`);
    await app.listen(port, '0.0.0.0');
    console.log(`🚀 RepAlign API is running on: http://0.0.0.0:${port}/${apiPrefix}`);
    console.log(`📖 Swagger docs available at: http://0.0.0.0:${port}/docs`);
    console.log(`💚 Health check: http://0.0.0.0:${port}/${apiPrefix}/health`);
  } catch (error) {
    console.error('❌ Failed to start application:', error);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

bootstrap();