using System.Collections.Generic;

namespace Inprotech.Tests.Integration.Utils
{
    public interface ITopoSortable
    {
        IEnumerable<ITopoSortable> Dependencies { get; }
    }

    class TopologicalSort
    {
        public List<ITopoSortable> Sort(IEnumerable<ITopoSortable> source)
        {
            var sorted = new List<ITopoSortable>();
            var visited = new Dictionary<ITopoSortable, bool>();

            foreach (var item in source)
            {
                Visit(item, sorted, visited);
            }

            return sorted;
        }

        private void Visit(ITopoSortable item, List<ITopoSortable> sorted, Dictionary<ITopoSortable, bool> visited)
        {
            bool inProcess;
            var alreadyVisited = visited.TryGetValue(item, out inProcess);

            if (alreadyVisited)
            {
                if (inProcess)
                {
                    //throw new ArgumentException("Cyclic dependency found.");
                }
            }
            else
            {
                visited[item] = true;

                var dependencies = item.Dependencies;
                if (dependencies != null)
                {
                    foreach (var dependency in dependencies)
                    {
                        Visit(dependency, sorted, visited);
                    }
                }

                visited[item] = false;
                sorted.Add(item);
            }
        }
    }
}
