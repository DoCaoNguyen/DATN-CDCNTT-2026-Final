import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export async function GET() {
  return NextResponse.json({
    apiKey: process.env.MERCHANT_API_KEY || '',
    secretKey: process.env.MERCHANT_SECRET_KEY || ''
  });
}

export async function POST(req: NextRequest) {
  try {
    const { apiKey, secretKey } = await req.json();
    
    const envPath = path.join(process.cwd(), '.env.local');
    let envContent = '';
    
    if (fs.existsSync(envPath)) {
      envContent = fs.readFileSync(envPath, 'utf8');
    }
    
    // Update or add MERCHANT_API_KEY
    if (envContent.includes('MERCHANT_API_KEY=')) {
      envContent = envContent.replace(/MERCHANT_API_KEY=.*/g, `MERCHANT_API_KEY="${apiKey}"`);
    } else {
      envContent += `\nMERCHANT_API_KEY="${apiKey}"`;
    }
    
    // Update or add MERCHANT_SECRET_KEY
    if (envContent.includes('MERCHANT_SECRET_KEY=')) {
      envContent = envContent.replace(/MERCHANT_SECRET_KEY=.*/g, `MERCHANT_SECRET_KEY="${secretKey}"`);
    } else {
      envContent += `\nMERCHANT_SECRET_KEY="${secretKey}"`;
    }
    
    fs.writeFileSync(envPath, envContent);
    
    // Update process.env for current instance
    process.env.MERCHANT_API_KEY = apiKey;
    process.env.MERCHANT_SECRET_KEY = secretKey;
    
    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
