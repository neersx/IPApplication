using System.Reflection;

namespace InprotechKaizen.Database
{
    public static class ScriptUtility
    {
        public static bool Filter(this string scriptName, string collectionName)
        {
            return
                scriptName.StartsWith(string.Format("{0}.{1}", Assembly.GetExecutingAssembly().GetName().Name, collectionName));
        }
    }
}