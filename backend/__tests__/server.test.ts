import request from 'supertest';

describe('Health Check', () => {
  it('should return healthy status', async () => {
    const response = await request('http://localhost:4004')
      .get('/health')
      .expect(200);
    
    expect(response.body).toHaveProperty('status', 'healthy');
  });
});

describe('API Routes', () => {
  it('should have auth routes', async () => {
    const response = await request('http://localhost:4004')
      .post('/api/auth/login')
      .send({})
      .expect(200);
    
    expect(response.body).toBeDefined();
  });
});
