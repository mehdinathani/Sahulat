import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional

load_dotenv()

class FirebaseService:
    def __init__(self):
        self.db = self._initialize_firebase()

    def _initialize_firebase(self):
        # Allow forcing Mock DB via env var
        if os.getenv("USE_MOCK_DB", "").lower() in ("true", "1"):
            print("Forcing Local Mock DB via USE_MOCK_DB environment variable.")
            self.use_mock = True
            return MockFirestoreClient()

        # Check if already initialized
        try:
            if not firebase_admin._apps:
                cred_path = os.getenv("FIREBASE_SERVICE_ACCOUNT", "service-account.json")
                if os.path.exists(cred_path) and "your_google_api_key_here" not in open(cred_path).read() and "MOCK_KEY" not in open(cred_path).read():
                    try:
                        cred = credentials.Certificate(cred_path)
                        firebase_admin.initialize_app(cred)
                    except Exception as e:
                        print(f"Warning: Failed to load service account: {e}. Falling back to default.")
                        try:
                            firebase_admin.initialize_app()
                        except Exception as e2:
                            print(f"Warning: Default init also failed: {e2}. Using Mock DB.")
                            self.use_mock = True
                            return MockFirestoreClient()
                else:
                    # On Cloud Run, use Application Default Credentials
                    try:
                        firebase_admin.initialize_app()
                    except Exception as e:
                        print(f"Warning: firebase_admin.initialize_app() failed: {e}. Using Mock DB.")
                        self.use_mock = True
                        return MockFirestoreClient()
            # Try creating the Firestore client — this can fail if DB doesn't exist
            try:
                client = firestore.client()
                self.use_mock = False
                print("Firestore client initialized successfully.")
                return client
            except Exception as e:
                print(f"Warning: firestore.client() failed: {e}. Using Local Mock DB.")
                self.use_mock = True
                return MockFirestoreClient()
        except Exception as e:
            print(f"Critical: Firebase initialization failed: {e}. Using Local Mock DB.")
            self.use_mock = True
            return MockFirestoreClient()

    def _execute_with_fallback(self, func):
        try:
            return func(self.db)
        except Exception as e:
            if not self.use_mock:
                print(f"Warning: Firestore operation failed ({e}). Falling back to Local Mock DB.")
                self.use_mock = True
                self.db = MockFirestoreClient()
                return func(self.db)
            raise e

    def get_document(self, collection: str, document_id: str) -> Optional[Dict[str, Any]]:
        def _op(db):
            doc_ref = db.collection(collection).document(document_id)
            doc = doc_ref.get()
            return doc.to_dict() if doc.exists else None
        return self._execute_with_fallback(_op)

    def add_document(self, collection: str, data: Dict[str, Any], document_id: Optional[str] = None) -> str:
        def _op(db):
            if document_id:
                db.collection(collection).document(document_id).set(data)
                return document_id
            else:
                _, doc_ref = db.collection(collection).add(data)
                return doc_ref.id
        return self._execute_with_fallback(_op)

    def update_document(self, collection: str, document_id: str, data: Dict[str, Any]):
        def _op(db):
            db.collection(collection).document(document_id).update(data)
        self._execute_with_fallback(_op)

    def query_collection(self, collection: str, filters: List[tuple]) -> List[Dict[str, Any]]:
        def _op(db):
            query = db.collection(collection)
            for field, op, value in filters:
                query = query.where(field, op, value)
            docs = query.stream()
            return [{"id": doc.id, **doc.to_dict()} for doc in docs]
        return self._execute_with_fallback(_op)

    def delete_document(self, collection: str, document_id: str):
        def _op(db):
            db.collection(collection).document(document_id).delete()
        self._execute_with_fallback(_op)

import json

class MockFirestoreClient:
    """A minimal mock for Firestore client for local development with persistence."""
    def __init__(self, storage_file="mock_db.json"):
        self.storage_file = storage_file
        self.data = self._load_data()

    def _load_data(self):
        if os.path.exists(self.storage_file):
            try:
                with open(self.storage_file, "r") as f:
                    return json.load(f)
            except:
                return {}
        return {}

    def _save_data(self):
        with open(self.storage_file, "w") as f:
            json.dump(self.data, f, indent=2)

    def collection(self, name):
        if name not in self.data:
            self.data[name] = {}
        return MockCollection(name, self.data[name], self._save_data)

class MockCollection:
    def __init__(self, name, docs_data, save_callback):
        self.name = name
        self.docs_data = docs_data
        self.save_callback = save_callback

    def document(self, id):
        return MockDocument(id, self.docs_data, self.save_callback)

    def add(self, data):
        import uuid
        doc_id = str(uuid.uuid4())
        self.docs_data[doc_id] = data
        self.save_callback()
        return None, MockDocument(doc_id, self.docs_data, self.save_callback)

    def where(self, field, op, value):
        # We return a Query object that can filter
        return MockQuery(self.docs_data, field, op, value)

    def stream(self):
        return [MockDocument(id, self.docs_data, self.save_callback) for id in self.docs_data]

class MockQuery:
    def __init__(self, docs_data, field, op, value):
        self.docs_data = docs_data
        # Simple filtering logic
        self.filtered_ids = []
        for doc_id, data in docs_data.items():
            if op == "==" and data.get(field) == value:
                self.filtered_ids.append(doc_id)
            # Add more operators if needed

    def stream(self):
        return [MockDocument(id, self.docs_data, lambda: None) for id in self.filtered_ids]

class MockDocument:
    def __init__(self, id, docs_data, save_callback):
        self.id = id
        self.docs_data = docs_data
        self.save_callback = save_callback
        self.exists = id in docs_data

    def get(self):
        return self

    def to_dict(self):
        return self.docs_data.get(self.id, {})

    def set(self, data):
        self.docs_data[self.id] = data
        self.exists = True
        self.save_callback()

    def update(self, data):
        if self.id in self.docs_data:
            self.docs_data[self.id].update(data)
            self.save_callback()

    def delete(self):
        if self.id in self.docs_data:
            del self.docs_data[self.id]
            self.exists = False
            self.save_callback()

# Singleton instance
firebase_service = FirebaseService()
