from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List

app = FastAPI()

# Global CORS (Cross-Origin Resource Sharing) middleware settings
origins = ["http://localhost:8000"]  # Adjust the allowed origin to match your frontend's URL

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Book(BaseModel):
    isbn: str
    title: str
    author: str
    coverType: str

# Store books in a dictionary using ISBN as the key
books_db = {}

@app.get("/books")
def get_books():
    # Return the list of books
    return {"books": list(books_db.values())}

@app.post("/books")
def add_book(book: Book):
    # Check if the ISBN already exists
    if book.isbn in books_db:
        raise HTTPException(status_code=400, detail="Book with this ISBN already exists")
    
    # Add the new book to the database
    books_db[book.isbn] = book.dict()
    return {"status": "Book added successfully"}

@app.put("/books/{isbn}")
def update_book(isbn: str, book_update: Book):
    # Check if the ISBN exists
    if isbn not in books_db:
        raise HTTPException(status_code=404, detail="Book not found")
    
    # Update the book in the database
    book = books_db[isbn]
    book.update(**book_update.dict())
    return {"status": "Book updated successfully"}


