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

# Initialize the list of books with some sample data
books = [
    Book(isbn="1234567890", title="Sample Book 1", author="Author 1"),
    Book(isbn="2345678901", title="Sample Book 2", author="Author 2"),
    # Add more books as needed
]

@app.get("/books", response_model=List[Book])
def list_books():
    return {"books": books}

@app.post("/books")
def add_book(book: Book):
    new_book = {
        "isbn": book.isbn,
        "title": book.title,
        "author": book.author
    }
    books.append(new_book)
    return new_book