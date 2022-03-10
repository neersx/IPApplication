using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;

namespace Inprotech.Utility.ConfigSso
{
    internal static class Tools
    {
        private static readonly Dictionary<EnvironmentType, St> Map
            = new Dictionary<EnvironmentType, St>
            {
                {
                    EnvironmentType.Staging, new St
                    {
                        M = "https://staging.ipplatform.com",
                        S = "https://sso-staging.ipplatform.com",
                        I = "https://users.sso-staging.ipplatform.com",
                        C =
                            "MIIC6jCCAdKgAwIBAgIGAW2MzEhNMA0GCSqGSIb3DQEBDQUAMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpDUEEgR2xvYmFsMRIwEAYDVQQDEwlKV1QgVG9rZW4wHhcNMTkxMDAyMTQwNzQxWhcNMjkwOTI5MTQwNzQxWjA2MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQ1BBIEdsb2JhbDESMBAGA1UEAxMJSldUIFRva2VuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnzrRQbfHAkMgclinEDjepGwelDAjD233Nrk7dqx2D2hfjhbumkULhYP0vjuXDcJ3cIpzOVcE4YDmKypcU27tNUDjGx66wxv0UxJ82xfH1JEup7zAdIeBrmpU8DtS02f9Mehi8qt3Iagh9NMrVo86uGskNi32IHXu6iljuKrV2ww51TezSMvY5SEAMYolQ/6yqy5+pHNhrQiU/xGswyry8W9VBxLOODmOcR8+a9ts4kfrwt92xBdroa670AHZg2th6vdfLhan+ef8wQIwKYk7Ros0glXJYqBWdXfu/L9lHy17D187J2IAJT/yuGiDL34Aml+1Xci9ICvCE0ANkHORZwIDAQABMA0GCSqGSIb3DQEBDQUAA4IBAQBmvt8ugIFejyiRSWSk3+nT1S1853GAi61l2hjkiQKulVDLJ5QCUDmtY5Wwu3/MKuLC0Q4N5MjGQs9KaVaubLWmiLsxmdEbbzVPc3u2FZfD6FiLmknrrLa2JQTp3WIqQ1WFshywDq68BQReSINabxzM0R76W//Vq9fM34zzr9tZifwFZJyDFZavLELEL2o+V6Yu7n29smF5gaANUaEMaNmqw92GR6pewFylY7A+57GvSMpU7RNZmc1P0YU3A4oG9dp92q+spBjEx/bj7S05+nllUznJf+TeDlngMJMJgryZncgdAavtY1Cyx1I5bk0nOdTqfBCsKM7eLwHZiv2pUyxC",
                        A = "https://az01-sd-file-apiexternal-staging.azurewebsites.net"
                    }
                },
                {
                    EnvironmentType.Preprod, new St
                    {
                        M = "https://preprod.ipplatform.com",
                        S = "https://sso-preprod.ipplatform.com",
                        I = "https://users.sso-preprod.ipplatform.com",
                        C =
                            "MIIC6jCCAdKgAwIBAgIGAVg7EMBoMA0GCSqGSIb3DQEBCwUAMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpDUEEgR2xvYmFsMRIwEAYDVQQDEwlTU08gVG9rZW4wHhcNMTYxMTA2MTkxNTAzWhcNMjYxMTA0MTkxNTAzWjA2MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQ1BBIEdsb2JhbDESMBAGA1UEAxMJU1NPIFRva2VuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAm2dgPxURoIJNQxcxG18XteeU3H//4LBOB1uVsLt5wO0E6feoJh6TiSQ8YIGeI623BUVqLDU5PNjoWF3MQQEcv+FiQ6is1CV5aU4kmmPHNP13ebkzOmAD65WAPY5kGI4bhT57vYZIEVEzNynjVUJd8JcNE2QGrSWd/gBYxFGc+R4RJLGgEzGfxIFYjhGmhYgi7kX+5cO+QQpcSIhPazRUjpFOObGyl7rWzIdtrr8aXAK8NiHL6w10jBv6gd5HFOpAhR7+OzFWbgLiHf/cptyplvmnDplJ27maS9eUVN64ld3B/Pj+KO/aOyRyqYq5ygHGl6utTzBHC3puYYvXChOtdwIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAPPrcD58o+mvqTOiLsW4oExJQlelufs+rGX6r4YILSKiPRbnBaQ5NfJP1fIkubzpmpxrusclJSUEOQSAsh7Tb2W3qiuSYe+LcEZaBbCgOT+xKhehTBHnqMCa6SPjiotXZzWvp4ZvP8/xUo7NxLjn7RVnoNwLoQbsL5YBwntC9SMeWYN9zMf6JWGaSBtenV9nH7FRKiYQK2usel9TUUST2C+w33XVqKLmp12Gz+mGiIWunD+n/e0xfdJDQ+KdoKG0yY4rcROQ/4dWw0XR4sD07+fqRUPPV0ka271t4cDriop3EJddnkAkh4+faEyk5K11leHSk3qAHNZ1r0OxWEg3vo​",
                        A = "https://api.preprod.ipplatform.com"
                    }
                },
                {
                    EnvironmentType.Prod, new St
                    {
                        M = "https://www.ipplatform.com",
                        S = "https://sso.ipplatform.com",
                        I = "https://users.sso.ipplatform.com",
                        C =
                            "MIIC6jCCAdKgAwIBAgIGAWbepqO3MA0GCSqGSIb3DQEBCwUAMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpDUEEgR2xvYmFsMRIwEAYDVQQDEwlTU08gVG9rZW4wHhcNMTgxMTA0MTIxNTU0WhcNMjgxMTAxMTIxNTU0WjA2MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQ1BBIEdsb2JhbDESMBAGA1UEAxMJU1NPIFRva2VuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw8JMjTuf5lwYlXgKptamrwSFpl3FQ3I+1bv2NpTRlxSuM/zKSw77bp81hURXM6tYMlBSwEkb0+N7UoODMNWMCW1YWRrom6QcspjjGEGZgemyfpNV5CXM/ODnJPGtmGXpIXhLXrtvtVvwoHR5WPshtwFB9aUiu4oMdSIn16dOgMC2qtuNcQJQQEVc97ruq4O/ROrg3Qnq7NS+g07TiAlyyqSfUhh17Qh6NRbnd+jIFGAjzAeEEZwQmrBNDbkSKz4vdDeQna+mfuLC9Ho87mb43mo4W9UVvhh/5TbcXRHFu68CoMMdgLmlf1i4Y/CvUtjS/ulqROQ1aEv1Xc5uQQOC1QIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQCoIJhkqOiyJB/MsmLgTgygwpShItCFAH88uiHE13bGNx34D0ILq2rbYlMCJWKiJ/N9xz28qxxVJbUqJPGABn1wyEMW2YfDxq6MREcbrMWdLHyIA+xjRvUhQk8shcuEhI+BKsc03dtQY4ppEEGZQeJiRFbeXPcx4vGCIHbgPg7y7SWd8FUQdjLfO055GKBQ7kOemz4QKTMY4lV6hZrGis1KN2aw1qY2vAPwbyYzsjt9k55//eP00xKdDVRV4q03GUnsA1VPVjhWtEmvQIv5SE+hruVZNswLDDiuLewNTjhib0mvB1o0Lga+t35EZBRbHqV+puMiw1D6v0bM67OWYVn4",
                        A = "https://api.ipplatform.com"
                    }
                },
                {
                    EnvironmentType.Demo, new St
                    {
                        M = "https://na-demo.ipplatform.com",
                        S = "https://sso-na-demo.ipplatform.com",
                        I = "https://users.sso-na-demo.ipplatform.com",
                        C =
                            "MIIC6jCCAdKgAwIBAgIGAVzvRghhMA0GCSqGSIb3DQEBCwUAMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpDUEEgR2xvYmFsMRIwEAYDVQQDEwlTU08gVG9rZW4wHhcNMTcwNjI4MTUxNjAzWhcNMjcwNjI2MTUxNjAzWjA2MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQ1BBIEdsb2JhbDESMBAGA1UEAxMJU1NPIFRva2VuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuri1bU0FzoousOqeEYQG4frX2QA7Kv8jG8ZJ2Undvp3WSnkdtbcswNhA0R10fKvMI38E/zGqQy7XFYB4RzaruUDJ6lKE3SfmqNkjxjzmplfFhpjCvTob6+Xjz4DOBnQIiaTPbRGsMBVKNPYgQpOwB+fCNRDnJU54AAPxPttFNPDlwYBfQbwZW7lSudvlyzSyapZjRmq0pH9tDleC8Hp0el32+jDfy11uK4hOYZ4xIbHz6zYt004QDH/rIgM/cUlrSF+VDPPkQRqeHWRhyBScNd3i5np6sMc1ChbyCXzLrzJrZvUCSWqE2YrYBZ8oWCv67/MjYQoaeKVyQTDlBmfjvwIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQBXbMwh2WJ5/WBSGDeCqDdgw4ZdTCIlP01szL0sgPhlHTO38IoE3uk/o/hoZc2NhuUqTGne6NGMNuuizsQhARUu8E8qecilIIS6nH3RoiduzeIfbDZsbE/yCORP8QM4kyDNfsB/853UKkj4NXu+VtC5ygXj9IpnuoytOpdvbLkR8XtVTx/fASMfiatQxUW2w0UHfpJ1p4uqGFyJmAK4d9ENRrZNFqGqMXRu4KPHSF1lDLmUEdRwN79D3b4l1pUb1tWxGAbh1g9hkAJtCUgZ/aSdewEbUVeXavfOUbhTJtrgCIu8vmZTB1287tW/6hCgYK+28ROX0kmR1XVaodmi3Ra0",
                        A = "https://api.na-demo.ipplatform.com"
                    }
                }
            };
        
        internal static void SetEnvironment(string configFilePath, EnvironmentType env, Action<string> success, Action<string> failed)
        {
            var map = new ExeConfigurationFileMap { ExeConfigFilename = configFilePath };
            var configFile = ConfigurationManager.OpenMappedExeConfiguration(map, ConfigurationUserLevel.None);
            var s = configFile.AppSettings.Settings;

            if (Map.TryGetValue(env, out St v))
            {
                AddOrUpdate(s, "cpa.sso.serverUrl", v.S);
                AddOrUpdate(s, "cpa.sso.iamUrl", v.I);
                AddOrUpdate(s, "cpa.iam.proxy.serverUrl", v.I);
                AddOrUpdate(s, "cpa.sso.certificate", v.C);
                AddOrUpdate(s, "cpa.ipp.url", v.M);
                AddOrUpdate(s, "cpa.api.url", v.A);

                if (!configFile.AppSettings.SectionInformation.IsProtected)
                    configFile.AppSettings.SectionInformation.ProtectSection("DataProtectionConfigurationProvider");

                configFile.Save(ConfigurationSaveMode.Modified);

                success(configFilePath);
            }
            else
            {
                failed("Invalid Target Mode");
            }
        }

        private static void AddOrUpdate(KeyValueConfigurationCollection a, string k, string v)
        {
            if (string.IsNullOrWhiteSpace(v))
            {
                EnsureRemoved(a, k);
                return;
            }

            if (a.AllKeys.Contains(k))
                a[k].Value = v;
            else
                a.Add(k, v);
        }

        private static void EnsureRemoved(KeyValueConfigurationCollection a, string k)
        {
            if (a.AllKeys.Contains(k))
                a.Remove(k);
        }

        internal enum EnvironmentType
        {
            Staging = 1,
            Preprod = 2,
            Prod = 3,
            Demo = 4
        }

        private class St
        {
            public string S { get; set; }

            public string I { get; set; }

            public string C { get; set; }

            public string M { get; set; }

            public string A { get; set; }
        }
    }
}
