using System.Linq;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public interface IClassStringComparer
    {
        bool Equals(string classesA, string classesB);
    }

    public class ClassStringComparer : IClassStringComparer
    {
        public bool Equals(string classesA, string classesB)
        {
            if (classesA == classesB)
            {
                return true;
            }

            var a = MakeComparable(classesA);
            var b = MakeComparable(classesB);

            if (a.Count() != b.Count())
            {
                return false;
            }

            return string.Join(",", a) == string.Join(",", b);
        }

        static string[] MakeComparable(string concatenatedString)
        {
            return (concatenatedString ?? string.Empty)
                   .Split(',')
                   .Select(_ => _.Trim())
                   .Select(_ => _.TrimStart('0'))
                   .OrderBy(_ => _)
                   .ToArray();
        }
    }
}