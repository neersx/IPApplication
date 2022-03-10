using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using Microsoft.Win32;

namespace Inprotech.Setup.Actions.Utilities
{
    public interface IIwsSettingHelper
    {
        bool IsValidLocalAddress(string host);

        string GeneratePrivateKey();

        string ResolveInstallationLocation();

        bool HasExistingSetting(string connectionString, string providerName);

        string GetExistingSettingValue(string connectionString, string providerName);

        void SaveExternalSetting(string connectionString, string settingString, bool isComplete, string providerName);

        void UpdateExistingSetting(string connectionString, string settingString, bool isComplete, string providerName);
    }

    public class IwsSettingHelper : IIwsSettingHelper
    {
        public bool IsValidLocalAddress(string host)
        {
            if (string.IsNullOrWhiteSpace(host))
                return false;
            try
            {
                var hostIPs = Dns.GetHostAddresses(host);
                var localIPs = Dns.GetHostAddresses(Dns.GetHostName());

                foreach (var hostIp in hostIPs)
                {
                    if (IPAddress.IsLoopback(hostIp)) return true;
                    foreach (var localIp in localIPs)
                    {
                        if (hostIp.Equals(localIp)) return true;
                    }
                }
            }
            catch
            {
                return false;
            }

            return false;
        }

        public string GeneratePrivateKey()
        {
            return Guid.NewGuid().ToString().Substring(0, 16);
        }

        public string ResolveInstallationLocation()
        {
            try
            {
                var iwsRegKeyLocation = Environment.Is64BitOperatingSystem
                    ? @"SOFTWARE\WOW6432Node\CPA Global\Inprotech Server Software\Inpro Windows Services"
                    : @"SOFTWARE\CPA Global\Inprotech Server Software\Inpro Windows Services";

                var iwsRegKey = Registry.LocalMachine.OpenSubKey(iwsRegKeyLocation, RegistryKeyPermissionCheck.ReadSubTree);
                var value = (string)iwsRegKey?.GetValue("path");

                return !string.IsNullOrWhiteSpace(value) && Directory.Exists(value)
                    ? value
                    : null;
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
                throw;
            }
        }
        
        public bool HasExistingSetting(string connectionString, string providerName)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = @"SELECT COUNT(*) FROM EXTERNALSETTINGS WHERE PROVIDERNAME = @providerName;";

                var param = command.Parameters.Add("@providerName", SqlDbType.NVarChar, 254);
                param.Value = providerName;
                return (int)command.ExecuteScalar() != 0;
            }
        }

        public string GetExistingSettingValue(string connectionString, string providerName)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = @"SELECT SETTINGS FROM EXTERNALSETTINGS WHERE PROVIDERNAME = @providerName;";

                var param = command.Parameters.Add("@providerName", SqlDbType.NVarChar, 254);
                param.Value = providerName;
                return (string)command.ExecuteScalar();
            }
        }

        public void SaveExternalSetting(string connectionString, string settingString, bool isComplete, string providerName)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = @"IF NOT EXISTS( SELECT * FROM EXTERNALSETTINGS WHERE PROVIDERNAME = @providerName)
                                            INSERT INTO EXTERNALSETTINGS(PROVIDERNAME, Settings, ISCOMPLETE)
                                            VALUES(@providerName, @setting, @complete);";

                var paramSettings = command.Parameters.Add("@setting", SqlDbType.NVarChar, -1);
                paramSettings.Value = settingString;

                var paramComplete = command.Parameters.Add("@complete", SqlDbType.Bit);
                paramComplete.Value = isComplete;

                var paramProviderName = command.Parameters.Add("@providerName", SqlDbType.NVarChar, -1);
                paramProviderName.Value = providerName;
                  
                command.ExecuteNonQuery();
            }
        }

        public void UpdateExistingSetting(string connectionString, string settingString, bool isComplete, string providerName)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = @"IF EXISTS( SELECT * FROM EXTERNALSETTINGS WHERE PROVIDERNAME = @providerName)
                                            UPDATE EXTERNALSETTINGS SET SETTINGS = @setting, ISCOMPLETE = @complete WHERE PROVIDERNAME = @providerName;";

                var paramSettings = command.Parameters.Add("@setting", SqlDbType.NVarChar, -1);
                paramSettings.Value = settingString;

                var paramComplete = command.Parameters.Add("@complete", SqlDbType.Bit);
                paramComplete.Value = isComplete;

                var paramProviderName = command.Parameters.Add("@providerName", SqlDbType.NVarChar, -1);
                paramProviderName.Value = providerName;
                  
                command.ExecuteNonQuery();
            }
        }
    }
}
