% An implementation of the partially absorbing label propagation
% algorithm described in:
%
%   Neumann, M., Garnett, R., and Kersting, K. Coinciding Walk
%   Kernels: Parallel Absorbing Random Walks for Learning with Graphs
%   and Few Labels. (2013). To appear in: Proceedings of the 5th
%   Annual Asian Conference on Machine Learning (ACML 2013).
%
% function probabilities = label_propagation(problem, train_ind, ...
%   observed_labels, test_ind, A, varargin)
%
% required inputs:
%           problem: a struct describing the problem, containing
%                    the field:
%
%             num_classes: the number of classes
%
%         train_ind: a list of indices into indicating the training
%                    nodes
%   observed_labels: a list of labels corresponding to the
%                    observations in train_ind
%          test_ind: a list of indices into A comprising the test
%                    nodes
%                 A: a weighted adjacency matrix for the desired graph
%                    containing transition probabilities. A should be
%                    row-normalized.
%
% optional named arguments specified after requried inputs:
%      'num_iterations': the number of label propagation iterations to
%                        perform (default: 200)
%               'alpha': the absorbtion parameter to use in [0, 1]
%                        (default: 1, corresponds to standard label
%                        propagation)
%           'use_prior': a boolean indicating whether to use the
%                        empirical distribution on the training points
%                        as the prior (true) or a uniform prior
%                        (false) (default: false)
%         'pseudocount': if use_prior is set to true, a per-class
%                        pseudocount can also be specified (default: 1)
%
% output:
%   probabilities: a matrix containing the probabilities on the
%                  test points. probabilities(i, k) gives
%
%                    Pr(x(test_ind(i), :) == k | D)
%
% Copyright (c) Roman Garnett, 2014

function probabilities = label_propagation(problem, train_ind, ...
  observed_labels, test_ind, A, varargin)

  % parse optional inputs
  options = inputParser;

  options.addParamValue('num_iterations', 200, ...
                        @(x) (isscalar(x) && (x >= 0)));
  options.addParamValue('alpha', 1, ...
                        @(x) (isscalar(x) && (x >= 0) && (x <= 1)));
  options.addParamValue('use_prior', false, ...
                        @(x) (islogical(x) && (numel(x) == 1)));
  options.addParamValue('pseudocount', 0.1, ...
                        @(x) (isscalar(x) && (x > 0)));

  options.parse(varargin{:});
  options = options.Results;

  % check whether A is row-normalized
  if (any(sum(A) ~= 1))
    A = bsxfun(@times, A, 1 ./ sum(A, 2));
  end

  num_nodes   = size(A, 1);
  num_classes = problem.num_classes;
  num_train   = numel(train_ind);

  if (options.use_prior)
    prior = options.pseudocount + ...
            accumarray(observed_labels, 1, [1, num_classes]);
    prior = prior * (1 ./ sum(prior));
  else
    prior = ones(1, num_classes) * (1 / num_classes);
  end

  % expand graph with pseudonodes corresponding to the classes
  num_expanded_nodes = num_nodes + num_classes;

  A = [A, sparse(num_nodes, num_classes); ...
       sparse(num_classes, num_expanded_nodes)];

  % reduce weight of edges leaving training nodes by a factor of
  % (1 - alpha)
  A(train_ind, :) = (1 - options.alpha) * A(train_ind, :);

  % add edges from training nodes to label nodes with weight alpha
  A = A + sparse(train_ind, num_nodes + observed_labels, options.alpha, ...
                 num_expanded_nodes, num_expanded_nodes);

  % add self loops on label nodes
  pseudo_train_ind = (num_nodes + 1):num_expanded_nodes;
  A(pseudo_train_ind, pseudo_train_ind) = speye(num_classes);

  % begin with prior on all nodes
  probabilities = repmat(prior, [num_nodes + num_classes, 1]);

  % fill in known training labels
  probabilities(train_ind, :) = ...
      accumarray([(1:num_train)', observed_labels], 1, [num_train, num_classes]);

  % add knwon labels for label nodes
  probabilities(pseudo_train_ind, :) = eye(num_classes);

  for i = 1:options.num_iterations
    % propagate labels
    probabilities = A * probabilities;
  end

  probabilities = probabilities(test_ind, :);
end