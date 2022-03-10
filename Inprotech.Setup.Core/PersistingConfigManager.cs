using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using NLog;

namespace Inprotech.Setup.Core
{
    public interface IPersistingConfigManager
    {
        Task<Dictionary<string, string>> GetValues(string connectionString, params string[] keys);
        Task SetValues(string connectionString, Dictionary<string, string> values);
        Task RemoveConfig(string connectionString, params string[] keys);
    }

    public class PersistingConfigManager : IPersistingConfigManager
    {
        static readonly Logger Logger = LogManager.GetCurrentClassLogger();

        readonly string _group;

        public PersistingConfigManager(string group)
        {
            _group = group;
        }

        public async Task<Dictionary<string, string>> GetValues(string connectionString, params string[] keys)
        {
            var values = new Dictionary<string, string>();
            if (!keys.Any())
            {
                return values;
            }

            try
            {
                var keysStrings = keys.Select(BuildKey).ToList();
                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    var command = connection.CreateCommand();

                    command.CommandText = "IF EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CONFIGURATIONSETTINGS')"
                                          + $"BEGIN Select SettingKey, SettingValue from ConfigurationSettings where SettingKey in ({string.Join(",", keysStrings.Select((v, i) => "@p" + i))}) END";
                    for (var i = 0; i < keysStrings.Count; i++)
                        command.Parameters.AddWithValue("@p" + i, keysStrings[i]);

                    var reader = await command.ExecuteReaderAsync();

                    while (reader.Read())
                        values.Add(StripGroup(reader.GetString(0)), reader.GetString(1));
                }
            }
            catch (Exception ex)
            {
                Logger.Error(ex, $"Error while getting persisted config values for: {string.Join(",", keys)}");
            }

            return values;
        }

        public async Task SetValues(string connectionString, Dictionary<string, string> keyValues)
        {
            var valuesToBeUpdated = keyValues.Select(_ => new KeyValuePair<string, string>(BuildKey(_.Key), _.Value)).ToArray();
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                foreach (var keyValue in valuesToBeUpdated)
                {
                    var command = connection.CreateCommand();
                    command.CommandText = "IF EXISTS (SELECT * FROM CONFIGURATIONSETTINGS WHERE SettingKey = @SettingKey)"
                                          + " BEGIN UPDATE CONFIGURATIONSETTINGS SET SettingValue = @SettingValue WHERE SettingKey = @SettingKey END"
                                          + " ELSE BEGIN INSERT INTO CONFIGURATIONSETTINGS(SettingKey, SettingValue) VALUES (@SettingKey, @SettingValue) END";
                    command.Parameters.AddWithValue("@SettingKey", keyValue.Key);
                    command.Parameters.AddWithValue("@SettingValue", keyValue.Value);

                    await command.ExecuteNonQueryAsync();
                }
            }
        }

        public async Task RemoveConfig(string connectionString, params string[] keys)
        {
            if (!keys.Any())
            {
                return;
            }
            try
            {
                var keysStrings = keys.Select(BuildKey).ToList();
                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    var command = connection.CreateCommand();

                    command.CommandText = "IF EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CONFIGURATIONSETTINGS')"
                                          + $"BEGIN DELETE from ConfigurationSettings where SettingKey in ({string.Join(",", keysStrings.Select((v, i) => "@p" + i))}) END";
                    for (var i = 0; i < keysStrings.Count; i++)
                        command.Parameters.AddWithValue("@p" + i, keysStrings[i]);

                    await command.ExecuteNonQueryAsync();
                }
            }
            catch (Exception ex)
            {
                Logger.Error(ex, $"Error while getting persisted config values for: {string.Join(",", keys)}");
            }
        }

        string BuildKey(string key)
        {
            return string.IsNullOrWhiteSpace(_group) ? key : $"{_group}.{key}";
        }

        string StripGroup(string key)
        {
            return string.IsNullOrWhiteSpace(_group) ? key : key.Replace($"{_group}.", string.Empty);
        }
    }
}