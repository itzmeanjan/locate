package com.example.itzmeanjan.locate

import android.app.Activity
import android.content.Context
import android.content.IntentSender
import android.content.pm.PackageManager
import android.location.LocationManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.common.ConnectionResult.SUCCESS
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.view.FlutterView

class LocatePlugin(private val registrar: Registrar, private val flutterView: FlutterView, private val activity: Activity) : MethodCallHandler {

    private var eventChannel: EventChannel? = null
    // will be used later to control flow of data( location updates ), from platform side to UI
    private var fusedLocationProviderClient: FusedLocationProviderClient? = null
    private var locationManager: LocationManager? = null
    private var locationCallback: MyLocationCallBack? = null
    private var locationListener: MyLocationListener? = null
    private var eventSink: EventChannel.EventSink? = null
    // up to this place
    private val permissionsToBeGranted: List<String> = listOf(android.Manifest.permission.ACCESS_FINE_LOCATION, android.Manifest.permission.ACCESS_COARSE_LOCATION)

    companion object {
        private var permissionCallBack: PermissionCallBack? = null
        private var locationSettingsCallBack: LocationSettingsCallBack? = null
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val methodChannel = MethodChannel(registrar.messenger(), "io.github.itzmeanjan.locate.methodChannel")
            registrar.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
                when (requestCode) {
                    999 -> {
                        if(grantResults[0] == PackageManager.PERMISSION_GRANTED){
                            if(permissions[0] == android.Manifest.permission.ACCESS_FINE_LOCATION || permissions[0] == android.Manifest.permission.ACCESS_COARSE_LOCATION){
                                permissionCallBack?.granted()
                                true
                            }
                            else
                                false
                        }
                        else{
                            permissionCallBack?.denied()
                            false
                        }
                    }
                    else -> {
                        // ignoring anything else
                        false
                    }
                }
            }

            registrar.addActivityResultListener { requestCode, resultCode, _ ->
                when (requestCode) {
                    998 -> {
                        if (resultCode == Activity.RESULT_OK) {
                            locationSettingsCallBack?.enabled()
                            true
                        } else {
                            locationSettingsCallBack?.disabled()
                            false
                        }
                    }
                    else -> {
                        // doing nothing useful yet
                        false
                    }
                }
            }

            methodChannel.setMethodCallHandler(LocatePlugin(registrar, registrar.view(), registrar.activity()))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestLocationPermission" -> {
                // specializes in requesting location access permission
                permissionCallBack = object : PermissionCallBack {
                    override fun denied() {
                        result.success(0) // permission not granted
                    }

                    override fun granted() {
                        result.success(1) // permission granted
                    }
                }
                requestPermissions(index = call.argument<Int>("id")!!)
            }
            "enableLocation" -> {
                // asks user politely to enable location, if not enabled already
                locationSettingsCallBack = object : LocationSettingsCallBack {
                    override fun disabled() {
                        result.success(0) // location not enabled by user, notified to UI
                    }

                    override fun enabled() {
                        result.success(1) // location enabled by user
                    }
                }
                enableLocation()
            }
            "startLocationUpdate" -> { // starts location update listening service and sends data to UI using eventChannel
                eventChannel = EventChannel(flutterView, "io.github.itzmeanjan.locate.eventChannel")
                result.success(1)
                eventChannel?.setStreamHandler(
                        object : EventChannel.StreamHandler {
                            override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
                                if (p1 != null) {
                                    eventSink = p1
                                    val locationServiceProvider: String? = call.argument<String>("locationServiceProvider")
                                    val locationProvider: String? = call.argument<String>("locationProvider")
                                    if (locationServiceProvider == "0") {
                                        if (isGooglePlayServiceAvailable()) {
                                            fusedLocationProviderClient = FusedLocationProviderClient(activity.application)
                                            locationCallback = MyLocationCallBack(event = p1)
                                            if (locationCallback != null) {
                                                startPlayServiceBasedLocationUpdates(fusedLocationProviderClient!!, android.Manifest.permission.ACCESS_FINE_LOCATION, locationCallback!!)
                                            }
                                        } else {
                                            locationManager = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
                                            locationListener = MyLocationListener(event = p1)
                                            if (locationListener != null) {
                                                when (locationProvider) {
                                                    "gps" -> startLocationManagerBasedLocationUpdates(locationManager!!, LocationManager.GPS_PROVIDER, android.Manifest.permission.ACCESS_FINE_LOCATION, locationListener!!)
                                                    "network" -> startLocationManagerBasedLocationUpdates(locationManager!!, LocationManager.NETWORK_PROVIDER, android.Manifest.permission.ACCESS_COARSE_LOCATION, locationListener!!)
                                                    else -> {
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        locationManager = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
                                        locationListener = MyLocationListener(event = p1)
                                        if (locationListener != null) {
                                            when (locationProvider) {
                                                "gps" -> startLocationManagerBasedLocationUpdates(locationManager!!, LocationManager.GPS_PROVIDER, android.Manifest.permission.ACCESS_FINE_LOCATION, locationListener!!)
                                                "network" -> startLocationManagerBasedLocationUpdates(locationManager!!, LocationManager.NETWORK_PROVIDER, android.Manifest.permission.ACCESS_COARSE_LOCATION, locationListener!!)
                                                else -> {
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            override fun onCancel(p0: Any?) {
                                if (locationCallback != null && fusedLocationProviderClient != null) {
                                    fusedLocationProviderClient?.removeLocationUpdates(locationCallback)
                                    locationCallback = null
                                }
                                if (locationListener != null && locationManager != null) {
                                    locationManager?.removeUpdates(locationListener)
                                    locationListener = null
                                }
                            }
                        }
                )
            }
            "stopLocationUpdate" -> { // if you need to stop getting location updates, just invoke this method from UI level
                if (fusedLocationProviderClient != null) {
                    fusedLocationProviderClient?.removeLocationUpdates(locationCallback)
                    locationCallback = null
                    fusedLocationProviderClient = null
                }
                if (locationManager != null) {
                    locationManager?.removeUpdates(locationListener)
                    locationListener = null
                    locationManager = null
                }
                if (eventSink != null)
                    eventSink?.endOfStream()
                eventChannel = null
                result.success(1)
            }
            else -> result.notImplemented()
        }
    }

    private fun createLocationRequest(): LocationRequest {
        return LocationRequest.create().apply {
            interval = 10000
            fastestInterval = 5000
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }
    }

    private fun requestPermissions(index: Int = -1) {
        val tempList: List<String> = if (index > -1 && index < permissionsToBeGranted.size) {
            listOf(permissionsToBeGranted[index]).filter {
                !isPermissionAvailable(it)
            }
        } else {
            permissionsToBeGranted.filter {
                !isPermissionAvailable(it)
            }
        }
        if (tempList.isNotEmpty())
            ActivityCompat.requestPermissions(activity, tempList.toTypedArray(), 999)
        else
            permissionCallBack?.granted()
    }

    private fun startPlayServiceBasedLocationUpdates(fusedLocationProviderClient: FusedLocationProviderClient, permission: String, locationCallback: MyLocationCallBack) {
        if (ContextCompat.checkSelfPermission(activity.applicationContext, permission) == PackageManager.PERMISSION_GRANTED)
            fusedLocationProviderClient.requestLocationUpdates(createLocationRequest(), locationCallback, null)
    }

    private fun startLocationManagerBasedLocationUpdates(locationManager: LocationManager, provider: String, permission: String, locationListener: MyLocationListener) {
        if (ContextCompat.checkSelfPermission(activity.applicationContext, permission) == PackageManager.PERMISSION_GRANTED)
            locationManager.requestLocationUpdates(provider, 5000, 1.toFloat(), locationListener)
    }

    private fun enableLocation() {
        val locationRequest = createLocationRequest() //creates location requirements request object
        val builder = LocationSettingsRequest.Builder().addLocationRequest(locationRequest) // location request settings builder
        val client = LocationServices.getSettingsClient(activity.applicationContext) //location settings client
        val task = client.checkLocationSettings(builder.build())
        task.addOnSuccessListener {
            locationSettingsCallBack?.enabled()
        }
        task.addOnFailureListener {
            if (it is ResolvableApiException) {
                try {
                    it.startResolutionForResult(activity, 998)
                } catch (sendEx: IntentSender.SendIntentException) {
                    locationSettingsCallBack?.disabled()
                }
            }
        }
    }

    private fun isPermissionAvailable(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(activity.applicationContext, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun isGooglePlayServiceAvailable(): Boolean {
        return GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(activity.applicationContext) == SUCCESS
    }
}


interface PermissionCallBack {
    fun granted()
    fun denied()
}

interface LocationSettingsCallBack {
    fun enabled()
    fun disabled()
}