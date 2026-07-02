require('dotenv').config();
const { GoogleGenAI } = require('@google/genai');
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function test() {
  const question = "han muc va phi rut tien la bao nhieu trong ngay ?";
  const embedResult = await ai.models.embedContent({
    model: 'gemini-embedding-001',
    contents: question,
    config: { outputDimensionality: 768 },
  });
  const queryVector = embedResult.embeddings[0].values;
  
  const { data: documents, error } = await supabase.rpc('match_documents', {
    query_embedding: queryVector,
    match_threshold: 0.7,
    match_count: 3
  });
  
  console.log("Error:", error);
  console.log("Docs found with threshold 0.7:", documents?.length);
  
  const { data: docsLow, error: errLow } = await supabase.rpc('match_documents', {
    query_embedding: queryVector,
    match_threshold: 0.4,
    match_count: 3
  });
  console.log("Docs found with threshold 0.4:", docsLow?.length);
  if (docsLow?.length > 0) {
    console.log("Top doc similarity:", docsLow[0].similarity);
  }
}
test().catch(console.error);
