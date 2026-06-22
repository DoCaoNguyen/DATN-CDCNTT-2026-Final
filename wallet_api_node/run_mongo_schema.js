const mongoose = require('mongoose');

const uri = "mongodb://localhost:27017/ewallet_logs";

async function run() {
  try {
    await mongoose.connect(uri);
    const db = mongoose.connection.db;

    const collections = await db.listCollections().toArray();
    const collectionNames = collections.map(c => c.name);

    async function recreateCollection(name, validator, indexes = []) {
      if (collectionNames.includes(name)) {
        console.log(`[INFO] Collection ${name} already exists. Updating validator...`);
        await db.command({ collMod: name, validator, validationLevel: "moderate", validationAction: "warn" });
      } else {
        console.log(`[INFO] Creating collection ${name}...`);
        await db.createCollection(name, { validator, validationLevel: "moderate", validationAction: "warn" });
      }

      const coll = db.collection(name);
      for (const index of indexes) {
        await coll.createIndex(index.keys, index.options || {});
      }
    }

    const actorTypeEnum = ["USER", "MERCHANT", "ADMIN", "SYSTEM"];
    const logLevelEnum = ["INFO", "WARN", "ERROR", "CRITICAL"];
    const severityEnum = ["INFO", "WARN", "ERROR", "CRITICAL"];
    const webhookStatusEnum = ["PENDING", "SUCCESS", "RETRYING", "FAILED", "CANCELED"];

    await recreateCollection(
      "audit_logs",
      {
        $jsonSchema: {
          bsonType: "object",
          required: ["actor_type", "action", "entity_type", "created_at"],
          properties: {
            old_pg_id: { bsonType: ["long", "int", "null"], description: "Original PostgreSQL audit_logs.id when migrated" },
            trace_id: { bsonType: ["string", "null"], maxLength: 100 },
            actor_type: { enum: actorTypeEnum },
            actor_id: { bsonType: ["string", "null"], description: "UUID string" },
            action: { bsonType: "string", maxLength: 100 },
            entity_type: { bsonType: "string", maxLength: 100 },
            entity_id: { bsonType: ["string", "null"], description: "UUID string or null" },
            old_data: { bsonType: ["object", "array", "null"] },
            new_data: { bsonType: ["object", "array", "null"] },
            metadata: { bsonType: ["object", "array", "null"] },
            reason: { bsonType: ["string", "null"] },
            ip_address: { bsonType: ["string", "null"], maxLength: 45 },
            user_agent: { bsonType: ["string", "null"], maxLength: 500 },
            source_db: { bsonType: ["string", "null"] },
            source_table: { bsonType: ["string", "null"] },
            migrated_at: { bsonType: ["date", "null"] },
            created_at: { bsonType: "date" }
          }
        }
      },
      [
        { keys: { trace_id: 1 } },
        { keys: { actor_type: 1, actor_id: 1 } },
        { keys: { entity_type: 1, entity_id: 1 } },
        { keys: { action: 1 } },
        { keys: { created_at: -1 } },
        { keys: { source_table: 1, old_pg_id: 1 }, options: { unique: true, sparse: true } }
      ]
    );

    await recreateCollection(
      "system_logs",
      {
        $jsonSchema: {
          bsonType: "object",
          required: ["level", "module", "event", "message", "created_at"],
          properties: {
            old_pg_id: { bsonType: ["long", "int", "null"] },
            trace_id: { bsonType: ["string", "null"], maxLength: 100 },
            level: { enum: logLevelEnum },
            module: { bsonType: "string", maxLength: 100 },
            event: { bsonType: "string", maxLength: 100 },
            message: { bsonType: "string" },
            context: { bsonType: ["object", "array", "null"] },
            entity_type: { bsonType: ["string", "null"], maxLength: 100 },
            entity_id: { bsonType: ["string", "null"] },
            source_db: { bsonType: ["string", "null"] },
            source_table: { bsonType: ["string", "null"] },
            migrated_at: { bsonType: ["date", "null"] },
            created_at: { bsonType: "date" }
          }
        }
      },
      [
        { keys: { trace_id: 1 } },
        { keys: { level: 1 } },
        { keys: { module: 1 } },
        { keys: { event: 1 } },
        { keys: { entity_type: 1, entity_id: 1 } },
        { keys: { created_at: -1 } },
        { keys: { source_table: 1, old_pg_id: 1 }, options: { unique: true, sparse: true } }
      ]
    );

    await recreateCollection(
      "security_logs",
      {
        $jsonSchema: {
          bsonType: "object",
          required: ["event", "severity", "created_at"],
          properties: {
            old_pg_id: { bsonType: ["long", "int", "null"] },
            trace_id: { bsonType: ["string", "null"], maxLength: 100 },
            actor_type: { enum: [...actorTypeEnum, null] },
            actor_id: { bsonType: ["string", "null"] },
            event: { bsonType: "string", maxLength: 100 },
            severity: { enum: severityEnum },
            login_id: { bsonType: ["string", "null"] },
            success: { bsonType: ["bool", "null"] },
            failure_reason: { bsonType: ["string", "null"] },
            request_path: { bsonType: ["string", "null"] },
            ip_address: { bsonType: ["string", "null"], maxLength: 45 },
            user_agent: { bsonType: ["string", "null"], maxLength: 500 },
            metadata: { bsonType: ["object", "array", "null"] },
            source_db: { bsonType: ["string", "null"] },
            source_table: { bsonType: ["string", "null"] },
            migrated_at: { bsonType: ["date", "null"] },
            created_at: { bsonType: "date" }
          }
        }
      },
      [
        { keys: { trace_id: 1 } },
        { keys: { actor_type: 1, actor_id: 1 } },
        { keys: { event: 1 } },
        { keys: { severity: 1 } },
        { keys: { ip_address: 1 } },
        { keys: { created_at: -1 } },
        { keys: { source_table: 1, old_pg_id: 1 }, options: { unique: true, sparse: true } }
      ]
    );

    await recreateCollection(
      "api_request_logs",
      {
        $jsonSchema: {
          bsonType: "object",
          required: ["method", "path", "created_at"],
          properties: {
            trace_id: { bsonType: ["string", "null"], maxLength: 100 },
            actor_type: { enum: [...actorTypeEnum, null] },
            actor_id: { bsonType: ["string", "null"] },
            method: { enum: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"] },
            path: { bsonType: "string" },
            status_code: { bsonType: ["int", "null"], minimum: 100, maximum: 599 },
            duration_ms: { bsonType: ["int", "long", "null"], minimum: 0 },
            request_body: { bsonType: ["object", "array", "string", "null"] },
            response_body: { bsonType: ["object", "array", "string", "null"] },
            ip_address: { bsonType: ["string", "null"], maxLength: 45 },
            user_agent: { bsonType: ["string", "null"], maxLength: 500 },
            created_at: { bsonType: "date" }
          }
        }
      },
      [
        { keys: { trace_id: 1 } },
        { keys: { actor_type: 1, actor_id: 1 } },
        { keys: { method: 1, path: 1 } },
        { keys: { status_code: 1 } },
        { keys: { created_at: -1 } }
      ]
    );

    await recreateCollection(
      "user_activity_logs",
      {
        $jsonSchema: {
          bsonType: "object",
          required: ["actor_type", "action", "created_at"],
          properties: {
            trace_id: { bsonType: ["string", "null"], maxLength: 100 },
            actor_type: { enum: actorTypeEnum },
            actor_id: { bsonType: ["string", "null"] },
            action: { bsonType: "string", maxLength: 150 },
            screen: { bsonType: ["string", "null"] },
            entity_type: { bsonType: ["string", "null"] },
            entity_id: { bsonType: ["string", "null"] },
            metadata: { bsonType: ["object", "array", "null"] },
            ip_address: { bsonType: ["string", "null"], maxLength: 45 },
            user_agent: { bsonType: ["string", "null"], maxLength: 500 },
            device: { bsonType: ["object", "null"] },
            created_at: { bsonType: "date" }
          }
        }
      },
      [
        { keys: { trace_id: 1 } },
        { keys: { actor_type: 1, actor_id: 1 } },
        { keys: { action: 1 } },
        { keys: { entity_type: 1, entity_id: 1 } },
        { keys: { created_at: -1 } }
      ]
    );

    await recreateCollection(
      "webhook_attempt_logs",
      {
        $jsonSchema: {
          bsonType: "object",
          required: ["event_id", "merchant_id", "callback_url", "attempt_no", "status", "created_at"],
          properties: {
            old_pg_callback_id: { bsonType: ["string", "null"] },
            event_id: { bsonType: "string", maxLength: 100 },
            trace_id: { bsonType: ["string", "null"], maxLength: 100 },
            merchant_id: { bsonType: "string" },
            payment_order_id: { bsonType: ["string", "null"] },
            payment_transaction_id: { bsonType: ["string", "null"] },
            refund_transaction_id: { bsonType: ["string", "null"] },
            event_type: { bsonType: ["string", "null"] },
            callback_url: { bsonType: "string" },
            attempt_no: { bsonType: ["int", "long"], minimum: 0 },
            request_body: { bsonType: ["object", "array", "null"] },
            request_headers: { bsonType: ["object", "null"] },
            response_body: { bsonType: ["object", "array", "string", "null"] },
            http_status: { bsonType: ["int", "null"], minimum: 100, maximum: 599 },
            duration_ms: { bsonType: ["int", "long", "null"], minimum: 0 },
            error_message: { bsonType: ["string", "null"] },
            status: { enum: webhookStatusEnum },
            sent_at: { bsonType: ["date", "null"] },
            created_at: { bsonType: "date" },
            migrated_at: { bsonType: ["date", "null"] }
          }
        }
      },
      [
        { keys: { event_id: 1 } },
        { keys: { trace_id: 1 } },
        { keys: { merchant_id: 1 } },
        { keys: { payment_order_id: 1 } },
        { keys: { refund_transaction_id: 1 } },
        { keys: { status: 1 } },
        { keys: { created_at: -1 } },
        { keys: { old_pg_callback_id: 1, attempt_no: 1 }, options: { unique: true, sparse: true } }
      ]
    );

    await recreateCollection(
      "trace_events",
      {
        $jsonSchema: {
          bsonType: "object",
          required: ["trace_id", "event", "created_at"],
          properties: {
            trace_id: { bsonType: "string", maxLength: 100 },
            event: { bsonType: "string", maxLength: 150 },
            module: { bsonType: ["string", "null"], maxLength: 100 },
            actor_type: { enum: [...actorTypeEnum, null] },
            actor_id: { bsonType: ["string", "null"] },
            entity_type: { bsonType: ["string", "null"] },
            entity_id: { bsonType: ["string", "null"] },
            status: { bsonType: ["string", "null"] },
            message: { bsonType: ["string", "null"] },
            metadata: { bsonType: ["object", "array", "null"] },
            created_at: { bsonType: "date" }
          }
        }
      },
      [
        { keys: { trace_id: 1, created_at: 1 } },
        { keys: { module: 1 } },
        { keys: { event: 1 } },
        { keys: { entity_type: 1, entity_id: 1 } },
        { keys: { created_at: -1 } }
      ]
    );

    console.log(`[DONE] MongoDB log schema created/updated successfully.`);
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

run();
