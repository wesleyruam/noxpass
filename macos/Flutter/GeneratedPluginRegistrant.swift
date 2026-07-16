//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import cryptography_flutter
import file_selector_macos
import flutter_secure_storage_macos
import google_sign_in_ios
import local_auth_darwin
import share_plus
import sqlcipher_flutter_libs

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  CryptographyFlutterPlugin.register(with: registry.registrar(forPlugin: "CryptographyFlutterPlugin"))
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
  FlutterSecureStoragePlugin.register(with: registry.registrar(forPlugin: "FlutterSecureStoragePlugin"))
  FLTGoogleSignInPlugin.register(with: registry.registrar(forPlugin: "FLTGoogleSignInPlugin"))
  LocalAuthPlugin.register(with: registry.registrar(forPlugin: "LocalAuthPlugin"))
  SharePlusMacosPlugin.register(with: registry.registrar(forPlugin: "SharePlusMacosPlugin"))
  Sqlite3FlutterLibsPlugin.register(with: registry.registrar(forPlugin: "Sqlite3FlutterLibsPlugin"))
}
