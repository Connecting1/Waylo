<div align="center">
  <img src="assets/logo.png" alt="Waylo Logo" width="120"/>

  <h1>Waylo</h1>
  <p><strong>Enjoy Your Trip And Write It Down</strong></p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
    <img src="https://img.shields.io/badge/Django-092E20?style=for-the-badge&logo=django&logoColor=white"/>
    <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white"/>
  </p>
</div>

---

## About

Waylo is a mobile app that lets you record your travel memories on a map, share them with friends, and customize your own album. Pin your photos to the exact location they were taken, track the countries you've visited, and relive your journey — all in one place.

---

## Features

### Map
Visualize your travels on a world map. Zoom out to see the countries you've visited marked with their national flag — zoom in to see your photos pinned to the exact location they were taken.

<div align="center">
  <img src="assets/screenshots/map_world.png" width="250"/>
  <img src="assets/screenshots/map_detail.png" width="250"/>
</div>

<br/>

### Feed
Browse your friends' travel photos in a feed. Each post shows the photo along with its location on a map. Like and comment to share the experience.

<div align="center">
  <img src="assets/screenshots/feed.png" width="250"/>
</div>

<br/>

### Album
Customize your personal album canvas with widgets — add photos, text boxes, and bucket list checklists to make your travel diary truly yours.

<div align="center">
  <img src="assets/screenshots/album.png" width="250"/>
</div>

<br/>

### Location Sharing
Share your real-time location on the map. Your current position is displayed as your profile icon, with adjustable update intervals.

<div align="center">
  <img src="assets/screenshots/location_sharing.png" width="250"/>
</div>

<br/>

### Chat
Chat directly with your friends inside the app.

<div align="center">
  <img src="assets/screenshots/chat.png" width="250"/>
</div>

<br/>

### Friends
Search for users, send friend requests, and manage your friend list.

<div align="center">
  <img src="assets/screenshots/friends.png" width="250"/>
</div>

---

## Tech Stack

| | Technology |
|---|---|
| **Frontend** | Flutter |
| **Backend** | Django REST Framework |
| **Database** | PostgreSQL + PostGIS |
| **Map** | Mapbox |
| **Auth** | Google OAuth |

---

## Getting Started

### Requirements
- Flutter SDK 3.6.1
- Python 3.11.5
- PostgreSQL with PostGIS
- OSGeo4W (for GDAL/GEOS on Windows)

### Backend
```bash
cd waylo_api
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

### Frontend
```bash
cd waylo_flutter
flutter pub get
flutter run
```

---

## Developer

**Jihun Cho**
- GitHub: [@Jihun37](https://github.com/Jihun37)
