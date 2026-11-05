class City {
  const City(
    this.name,
    this.state,
    this.latitude,
    this.longitude, {
    this.utcOffsetMinutes = 330,
  });

  final String name;
  final String state;

  /// North-positive.
  final double latitude;

  /// East-positive.
  final double longitude;

  /// IST (+5:30) by default. Note: India used +6:30 "war time" from
  /// Sept 1942 to Oct 1945; births in that window need a correction.
  final int utcOffsetMinutes;

  String get label => '$name, $state';
}

// Approximate coordinates. Add more cities as users ask for them.
const indianCities = <City>[
  // West Bengal
  City('Kolkata', 'West Bengal', 22.5726, 88.3639),
  City('Howrah', 'West Bengal', 22.5958, 88.2636),
  City('Siliguri', 'West Bengal', 26.7271, 88.3953),
  City('Darjeeling', 'West Bengal', 27.0410, 88.2663),
  City('Durgapur', 'West Bengal', 23.5204, 87.3119),
  City('Asansol', 'West Bengal', 23.6739, 86.9524),
  City('Bardhaman', 'West Bengal', 23.2324, 87.8615),
  City('Kharagpur', 'West Bengal', 22.3460, 87.2320),
  City('Malda', 'West Bengal', 25.0108, 88.1411),
  City('Krishnanagar', 'West Bengal', 23.4058, 88.4907),
  City('Haldia', 'West Bengal', 22.0667, 88.0698),
  City('Bankura', 'West Bengal', 23.2324, 87.0716),
  City('Jalpaiguri', 'West Bengal', 26.5167, 88.7333),
  City('Cooch Behar', 'West Bengal', 26.3240, 89.4510),
  City('Baharampur', 'West Bengal', 24.1000, 88.2500),
  City('Medinipur', 'West Bengal', 22.4247, 87.3199),
  City('Purulia', 'West Bengal', 23.3320, 86.3650),
  City('Barasat', 'West Bengal', 22.7230, 88.4800),
  // East / North-East
  City('Guwahati', 'Assam', 26.1445, 91.7362),
  City('Silchar', 'Assam', 24.8333, 92.7789),
  City('Agartala', 'Tripura', 23.8315, 91.2868),
  City('Shillong', 'Meghalaya', 25.5788, 91.8933),
  City('Imphal', 'Manipur', 24.8170, 93.9368),
  City('Patna', 'Bihar', 25.5941, 85.1376),
  City('Gaya', 'Bihar', 24.7914, 85.0002),
  City('Bhagalpur', 'Bihar', 25.2425, 86.9842),
  City('Ranchi', 'Jharkhand', 23.3441, 85.3096),
  City('Jamshedpur', 'Jharkhand', 22.8046, 86.2029),
  City('Dhanbad', 'Jharkhand', 23.7957, 86.4304),
  City('Bhubaneswar', 'Odisha', 20.2961, 85.8245),
  City('Cuttack', 'Odisha', 20.4625, 85.8830),
  City('Puri', 'Odisha', 19.8135, 85.8312),
  // North
  City('New Delhi', 'Delhi', 28.6139, 77.2090),
  City('Lucknow', 'Uttar Pradesh', 26.8467, 80.9462),
  City('Kanpur', 'Uttar Pradesh', 26.4499, 80.3319),
  City('Varanasi', 'Uttar Pradesh', 25.3176, 82.9739),
  City('Prayagraj', 'Uttar Pradesh', 25.4358, 81.8463),
  City('Agra', 'Uttar Pradesh', 27.1767, 78.0081),
  City('Noida', 'Uttar Pradesh', 28.5355, 77.3910),
  City('Gurugram', 'Haryana', 28.4595, 77.0266),
  City('Chandigarh', 'Chandigarh', 30.7333, 76.7794),
  City('Amritsar', 'Punjab', 31.6340, 74.8723),
  City('Ludhiana', 'Punjab', 30.9010, 75.8573),
  City('Dehradun', 'Uttarakhand', 30.3165, 78.0322),
  City('Haridwar', 'Uttarakhand', 29.9457, 78.1642),
  City('Shimla', 'Himachal Pradesh', 31.1048, 77.1734),
  City('Jammu', 'Jammu & Kashmir', 32.7266, 74.8570),
  City('Srinagar', 'Jammu & Kashmir', 34.0837, 74.7973),
  City('Jaipur', 'Rajasthan', 26.9124, 75.7873),
  City('Jodhpur', 'Rajasthan', 26.2389, 73.0243),
  City('Udaipur', 'Rajasthan', 24.5854, 73.7125),
  // West / Central
  City('Mumbai', 'Maharashtra', 19.0760, 72.8777),
  City('Pune', 'Maharashtra', 18.5204, 73.8567),
  City('Nagpur', 'Maharashtra', 21.1458, 79.0882),
  City('Nashik', 'Maharashtra', 19.9975, 73.7898),
  City('Ahmedabad', 'Gujarat', 23.0225, 72.5714),
  City('Surat', 'Gujarat', 21.1702, 72.8311),
  City('Vadodara', 'Gujarat', 22.3072, 73.1812),
  City('Rajkot', 'Gujarat', 22.3039, 70.8022),
  City('Bhopal', 'Madhya Pradesh', 23.2599, 77.4126),
  City('Indore', 'Madhya Pradesh', 22.7196, 75.8577),
  City('Ujjain', 'Madhya Pradesh', 23.1765, 75.7885),
  City('Raipur', 'Chhattisgarh', 21.2514, 81.6296),
  City('Panaji', 'Goa', 15.4909, 73.8278),
  // South
  City('Bengaluru', 'Karnataka', 12.9716, 77.5946),
  City('Mysuru', 'Karnataka', 12.2958, 76.6394),
  City('Mangaluru', 'Karnataka', 12.9141, 74.8560),
  City('Chennai', 'Tamil Nadu', 13.0827, 80.2707),
  City('Coimbatore', 'Tamil Nadu', 11.0168, 76.9558),
  City('Madurai', 'Tamil Nadu', 9.9252, 78.1198),
  City('Hyderabad', 'Telangana', 17.3850, 78.4867),
  City('Visakhapatnam', 'Andhra Pradesh', 17.6868, 83.2185),
  City('Vijayawada', 'Andhra Pradesh', 16.5062, 80.6480),
  City('Thiruvananthapuram', 'Kerala', 8.5241, 76.9366),
  City('Kochi', 'Kerala', 9.9312, 76.2673),
  City('Kozhikode', 'Kerala', 11.2588, 75.7804),
];
