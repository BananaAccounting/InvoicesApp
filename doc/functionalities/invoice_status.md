# Invoice status

We would like to add an invoice status in the json invoice.  
We should also be able to get an history of changes.  

## Json structure

```json
{
    "document_info": {
        "status": "..."
    },
    "history_info": [
        {
            "date": "2023-08-13T10:30:00",
            "author": "...",
            "note": "...",
            "event": "created",
        },
        {
            "date": "2023-08-13T10:30:00",
            "author": "...",
            "note": "Update address",
            "event": "updated",
        },
        {
            "date": "2023-08-13T10:30:00",
            "author": "...",
            "note": "...",
            "event": "sent",
        },
        {
            "date": "2023-08-13T10:30:00",
            "author": "...",
            "note": "...",
            "event": "sent"
        },
        {
            "date": "2023-08-13T10:30:00",
            "author": "...",
            "note": "...",
            "event": "first_reminder",
        }
        ,
        {
            "date": "2023-08-13T10:30:00",
            "author": "...",
            "note": "...",
            "event": "paid",
        }
}
```

The idea is to define a status that is the current status of the invoice, and then an history with a list of event done on the invoice.

Proposed new status for BananaPlus:

- draft
- completed
- sent
- paid
- first_reminder
- second_reminder
- third_reminder
- canceled
- contentious

Proposed history events:

- created
- updated
- completed
- sent
- paid
- partially_paid
- over_paid
- first_reminder
- second_reminder
- third_reminder
- canceled
- contentious

Currently in webmango we have following status (The reminder history is saved separately):

- _empty_
- completed
- canceled
- contentious
