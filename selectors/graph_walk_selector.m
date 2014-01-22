% A selector that compels observations to be taken along a connected
% path in a specified (possibly directed) graph. The nodes adjacent to
% the previously queried node are selected.
%
% function test_ind = graph_walk_selector(problem, train_ind, observed_labels, A)
%
% inputs:
%           problem: a struct describing the problem, containing fields:
%
%                  points: an (n x d) data matrix for the available points
%             num_classes: the number of classes
%             num_queries: the number of queries to make
%
%                    Note: this input is ignored by graph_walk_selector.
%                    If desired, it can be replaced by an empty matrix.
%
%         train_ind: a list of indices into problem.points indicating
%                    the thus-far observed points
%   observed_labels: a list of labels corresponding to the
%                    observations in train_ind
%
%                    Note: this input is ignored by graph_walk_selector.
%                    If desired, it can be replaced by an empty matrix.
%
%                 A: the (n x n) adjacency matrix for the desired
%                    graph. A nonzero entry for A(i, j) is interpreted
%                    as the presence of the (possibly directed) edge
%                    [i -> j].
%
% output:
%    test_ind: a list of indices into problem.points indicating the
%              points to consider for labeling. Each index in
%              test_ind can be reached from the last observed point
%              via an outgoing edge in the given graph.
%
% Copyright (c) Roman Garnett, 2013--2014

function test_ind = graph_walk_selector(~, train_ind, ~, A)

  test_ind = find(A(train_ind(end), :))';

end