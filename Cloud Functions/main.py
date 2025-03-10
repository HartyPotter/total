# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with firebase deploy

from firebase_functions import https_fn
from firebase_admin import initialize_app, firestore, credentials, messaging
from datetime import datetime
import json

initialize_app()

# Firestore client
db = firestore.client()


@https_fn.on_call()
def on_request_example(req: https_fn.CallableRequest) -> https_fn.Response:
    return https_fn.Response("Hello world!")


@https_fn.on_call()
def create_task(req: https_fn.CallableRequest) -> https_fn.Response:
    """
    Firebase Cloud Function to create a task in Firestore.
    Triggered by an HTTP request containing task data in JSON format.
    """
    try:
        # Parse the JSON data from the request body
        if not req.data:
            return https_fn.Response("No data provided", status=400)

        # Parse the JSON body
        task_data = req.data

        # Extract task fields from the JSON data
        task_name = task_data.get('name')
        task_source = task_data.get('source')
        task_destination = task_data.get('destination')
        assigned_driver_ref = task_data.get('assignedDriver')  # Firestore DocumentReference
        created_by_ref = task_data.get('createdBy')  # Firestore DocumentReference
        task_status = task_data.get('status', 'pending')  # Default to 'pending'
        task_type = task_data.get('type', 'pickup')  # Default to 'pickup'
        number_of_pallets = task_data.get('numberOfPallets', 0)
        estimated_time = task_data.get('estimatedTime', 0)
        is_queued = task_data.get('isQueued', False)

        # Create a Firestore document for the task
        task_ref = db.collection('tasks').document()
        task_id = task_ref.id  # Use the auto-generated ID

        # Prepare the task data for Firestore
        task_map = {
            'id': task_id,
            'name': task_name,
            'source': task_source,
            'destination': task_destination,
            'assignedDriver': assigned_driver_ref,
            'createdBy': created_by_ref,
            'status': task_status,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'type': task_type,
            'numberOfPallets': number_of_pallets,
            'estimatedTime': estimated_time,
            'isQueued': is_queued,
        }

        # Add the task to Firestore
        task_ref.set(task_map)

        # Send a notification to the assigned driver (if applicable)
        if assigned_driver_ref:
            driver_id = assigned_driver_ref.id  # Extract the driver ID from the DocumentReference
            supervisor_id = created_by_ref.id  # Extract the supervisor ID from the DocumentReference

            # Call the helper function to send the notification
            send_notification_to_driver(driver_id, task_name, supervisor_id)

        # Return a success response
        return https_fn.Response(json.dumps({'taskId': task_id}), status=200, headers={'Content-Type': 'application/json'})

    except Exception as e:
        print(f'Error in create_task function: {e}')
        return https_fn.Response(f'Internal Server Error: {e}', status=500)


def send_notification_to_driver(driver_id: str, task_name: str, supervisor_id: str) -> None:
    """
    Helper function to send a notification to a driver.
    """
    try:
        # Fetch the driver's FCM token
        driver_doc = db.collection('drivers').document(driver_id).get()

        if not driver_doc.exists:
            print('Driver not found')
            return

        driver_data = driver_doc.to_dict()
        fcm_token = driver_data.get('fcmToken')

        if not fcm_token:
            print('Driver FCM token not found')
            return

        # Fetch the supervisor's name
        supervisor_doc = db.collection('supervisors').document(supervisor_id).get()

        if not supervisor_doc.exists:
            print('Supervisor not found')
            return

        supervisor_data = supervisor_doc.to_dict()
        supervisor_name = supervisor_data.get('name', 'Unknown Supervisor')

        # Prepare the notification message
        message = messaging.Message(
            token=fcm_token,
            notification=messaging.Notification(
                title='New Task Assigned',
                body=f'You have a new task: {task_name} from {supervisor_name}',
            ),
            data={
                'taskName': task_name,
                'supervisorName': supervisor_name,
            },
        )

        # Send the notification
        response = messaging.send(message)
        print(f'Notification sent successfully: {response}')

    except Exception as e:
        print(f'Error in send_notification_to_driver helper function: {e}')