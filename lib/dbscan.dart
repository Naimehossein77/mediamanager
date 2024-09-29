import 'dart:math';

// Function to calculate Euclidean distance between two points
double euclideanDistance(List<double> point1, List<double> point2) {
  double sum = 0.0;
  for (int i = 0; i < point1.length; i++) {
    sum += pow(point1[i] - point2[i], 2);
  }
  return sqrt(sum);
}

// DBSCAN Algorithm in Dart
List<int> dbscan(List<List<double>> points, double eps, int minPts) {
  int cluster = 0;
  List<int> labels = List<int>.filled(points.length, -1); // -1 for noise, 0+ for clusters
  List<bool> visited = List<bool>.filled(points.length, false);

  for (int i = 0; i < points.length; i++) {
    if (visited[i]) continue;
    
    visited[i] = true;
    List<int> neighbors = regionQuery(points, i, eps);
    
    if (neighbors.length < minPts) {
      labels[i] = -1;  // Mark as noise
    } else {
      cluster++;
      expandCluster(points, labels, i, neighbors, cluster, eps, minPts, visited);
    }
  }
  return labels;
}

// Expand the cluster by adding neighboring points
void expandCluster(List<List<double>> points, List<int> labels, int pointIdx, List<int> neighbors, int cluster, double eps, int minPts, List<bool> visited) {
  labels[pointIdx] = cluster;
  
  for (int i = 0; i < neighbors.length; i++) {
    int neighborIdx = neighbors[i];
    if (!visited[neighborIdx]) {
      visited[neighborIdx] = true;
      List<int> neighborNeighbors = regionQuery(points, neighborIdx, eps);
      if (neighborNeighbors.length >= minPts) {
        neighbors.addAll(neighborNeighbors);
      }
    }
    if (labels[neighborIdx] == -1) {
      labels[neighborIdx] = cluster;
    }
  }
}

// Find all points within `eps` distance of point `pointIdx`
List<int> regionQuery(List<List<double>> points, int pointIdx, double eps) {
  List<int> neighbors = [];
  for (int i = 0; i < points.length; i++) {
    if (euclideanDistance(points[pointIdx], points[i]) <= eps) {
      neighbors.add(i);
    }
  }
  return neighbors;
}



// Example usage
void main() {
  List<List<double>> faceEmbeddings = [
    [0.1, 0.2, 0.3], // Point 1
    [0.2, 0.1, 0.4], // Point 2
    [0.9, 0.8, 0.7], // Point 3 (likely a different person)
    [0.9, 0.85, 0.75], // Point 4 (similar to Point 3)
  ];
  
  double eps = 0.5; // Max distance for a neighbor
  int minPts = 2;   // Minimum points to form a cluster

  List<int> clusters = dbscan(faceEmbeddings, eps, minPts);
  print(clusters); // Output: [1, 1, 2, 2] - Two clusters detected
}
